import AVFoundation
import CoreVideo
import Flutter
import Foundation

/// Native iOS video player engine powered by AVFoundation (AVPlayer).
///
/// Implements [FlutterTexture] to deliver decoded CVPixelBuffers directly
/// to Flutter's Metal texture registry with zero PlatformView overhead.
class BananaPlayer: NSObject, FlutterTexture, AVPlayerItemOutputPullDelegate {
  private(set) var textureId: Int64 = 0

  private let registry: FlutterTextureRegistry
  private let flutterApi: BananaPlayerFlutterApi
  private let registrar: FlutterPluginRegistrar
  private let player: AVPlayer

  private var currentItem: AVPlayerItem?
  private var videoOutput: AVPlayerItemVideoOutput?
  private var latestPixelBuffer: CVPixelBuffer?

  private var displayLink: CADisplayLink?
  private var timeObserverToken: Any?

  private var statusObserver: NSKeyValueObservation?
  private var timeControlObserver: NSKeyValueObservation?
  private var loadedTimeRangesObserver: NSKeyValueObservation?

  private var playbackSpeed: Float = 1.0
  private var selectedQualityId: String?
  private var isDisposed = false

  init(
    config: PlayerConfig,
    registry: FlutterTextureRegistry,
    flutterApi: BananaPlayerFlutterApi,
    registrar: FlutterPluginRegistrar
  ) {
    self.registry = registry
    self.flutterApi = flutterApi
    self.registrar = registrar
    self.player = AVPlayer()

    super.init()

    self.textureId = registry.register(self)

    configureAudioSession()

    player.actionAtItemEnd = .pause
    setVolume(Float(config.volume))

    setupTimeControlObserver()
    startTimeObserver()

    loadMedia(url: config.url, autoPlay: config.autoPlay)
  }

  // MARK: - Audio Session

  private func configureAudioSession() {
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playback, mode: .moviePlayback, options: [])
      try audioSession.setActive(true)
    } catch {
      print("[BananaPlayer] Failed to configure AVAudioSession: \(error)")
    }
  }

  // MARK: - Media Loading

  private func resolveMediaURL(from urlString: String) -> URL? {
    if urlString.hasPrefix("asset://") {
      var assetPath = String(urlString.dropFirst("asset://".count))
      while assetPath.hasPrefix("/") {
        assetPath = String(assetPath.dropFirst())
      }
      let key = registrar.lookupKey(forAsset: assetPath)
      if let path = Bundle.main.path(forResource: key, ofType: nil) {
        return URL(fileURLWithPath: path)
      }
      if let directPath = Bundle.main.path(forResource: assetPath, ofType: nil) {
        return URL(fileURLWithPath: directPath)
      }
      return nil
    } else if urlString.hasPrefix("/") {
      return URL(fileURLWithPath: urlString)
    } else if urlString.hasPrefix("file://") {
      return URL(string: urlString)
    } else {
      return URL(string: urlString)
    }
  }

  private func loadMedia(url: String, autoPlay: Bool) {
    guard let mediaUrl = resolveMediaURL(from: url) else {
      Task { @MainActor in
        try? await self.flutterApi.onError(
          textureId: self.textureId,
          errorCode: "INVALID_URL",
          errorMessage: "Invalid media URL or asset not found: \(url)"
        )
      }
      return
    }

    let asset = AVURLAsset(url: mediaUrl)
    let item = AVPlayerItem(asset: asset)

    // Back-buffer retention and automatic media selection
    item.canUseNetworkResourcesForLiveStreamingWhilePaused = true

    setupVideoOutput(for: item)
    setupItemObservers(for: item)

    self.currentItem = item
    player.replaceCurrentItem(with: item)

    if autoPlay {
      play()
    }
  }

  // MARK: - Video Output & FlutterTexture

  private func setupVideoOutput(for item: AVPlayerItem) {
    let pixelBuffAttributes: [String: Any] = [
      kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
      kCVPixelBufferIOSurfacePropertiesKey as String: [:] as [String: Any],
    ]
    let output = AVPlayerItemVideoOutput(pixelBufferAttributes: pixelBuffAttributes)
    output.setDelegate(self, queue: DispatchQueue.main)
    item.add(output)
    self.videoOutput = output
  }

  func outputMediaDataWillChange(_ sender: AVPlayerItemOutput) {
    registry.textureFrameAvailable(textureId)
  }

  func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
    guard let videoOutput = videoOutput else {
      if let latest = latestPixelBuffer {
        return Unmanaged.passRetained(latest)
      }
      return nil
    }

    let itemTime = videoOutput.itemTime(forHostTime: CACurrentMediaTime())
    if videoOutput.hasNewPixelBuffer(forItemTime: itemTime),
      let pixelBuffer = videoOutput.copyPixelBuffer(
        forItemTime: itemTime,
        itemTimeForDisplay: nil
      )
    {
      latestPixelBuffer = pixelBuffer
      return Unmanaged.passRetained(pixelBuffer)
    }

    if let latest = latestPixelBuffer {
      return Unmanaged.passRetained(latest)
    }
    return nil
  }

  // MARK: - CADisplayLink

  private func startDisplayLink() {
    guard displayLink == nil else { return }
    let link = CADisplayLink(target: self, selector: #selector(onDisplayLink(_:)))
    link.add(to: .main, forMode: .common)
    displayLink = link
  }

  private func stopDisplayLink() {
    displayLink?.invalidate()
    displayLink = nil
  }

  @objc private func onDisplayLink(_ link: CADisplayLink) {
    guard let videoOutput = videoOutput else { return }
    let itemTime = videoOutput.itemTime(forHostTime: CACurrentMediaTime())
    if videoOutput.hasNewPixelBuffer(forItemTime: itemTime) {
      registry.textureFrameAvailable(textureId)
    }
  }

  // MARK: - Observers

  private func setupTimeControlObserver() {
    timeControlObserver = player.observe(\.timeControlStatus, options: [.new]) {
      [weak self] player, _ in
      guard let self = self, !self.isDisposed else { return }
      switch player.timeControlStatus {
      case .playing:
        self.startDisplayLink()
        self.notifyPlaybackState(.ready)
      case .paused:
        self.stopDisplayLink()
        if self.getPosition() >= self.getDuration() && self.getDuration() > 0 {
          self.notifyPlaybackState(.ended)
        } else {
          self.notifyPlaybackState(.paused)
        }
      case .waitingToPlayAtSpecifiedRate:
        self.notifyPlaybackState(.buffering)
      @unknown default:
        break
      }
    }
  }

  private func setupItemObservers(for item: AVPlayerItem) {
    statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
      guard let self = self, !self.isDisposed else { return }
      switch item.status {
      case .readyToPlay:
        let isPlaying = self.player.timeControlStatus == .playing
        self.notifyPlaybackState(isPlaying ? .ready : .paused)
        self.notifyPosition()
        self.notifyVideoQualities()
      case .failed:
        let errorMsg = item.error?.localizedDescription ?? "Failed to load media item"
        Task { @MainActor in
          try? await self.flutterApi.onError(
            textureId: self.textureId,
            errorCode: "MEDIA_ERROR",
            errorMessage: errorMsg
          )
        }
      default:
        break
      }
    }

    loadedTimeRangesObserver = item.observe(\.loadedTimeRanges, options: [.new]) {
      [weak self] _, _ in
      self?.notifyPosition()
    }

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(itemDidPlayToEndTime(_:)),
      name: .AVPlayerItemDidPlayToEndTime,
      object: item
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(itemFailedToPlayToEndTime(_:)),
      name: .AVPlayerItemFailedToPlayToEndTime,
      object: item
    )
  }

  private func removeItemObservers() {
    statusObserver?.invalidate()
    statusObserver = nil

    loadedTimeRangesObserver?.invalidate()
    loadedTimeRangesObserver = nil

    if let current = currentItem {
      NotificationCenter.default.removeObserver(
        self,
        name: .AVPlayerItemDidPlayToEndTime,
        object: current
      )
      NotificationCenter.default.removeObserver(
        self,
        name: .AVPlayerItemFailedToPlayToEndTime,
        object: current
      )
    }
  }

  private func startTimeObserver() {
    stopTimeObserver()
    let interval = CMTime(value: 1, timescale: 5)  // 200ms
    timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) {
      [weak self] _ in
      self?.notifyPosition()
    }
  }

  private func stopTimeObserver() {
    if let token = timeObserverToken {
      player.removeTimeObserver(token)
      timeObserverToken = nil
    }
  }

  @objc private func itemDidPlayToEndTime(_ notification: Notification) {
    stopDisplayLink()
    notifyPlaybackState(.ended)
    notifyPosition()
  }

  @objc private func itemFailedToPlayToEndTime(_ notification: Notification) {
    let error =
      (notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error)?
      .localizedDescription ?? "Playback failed"
    Task { @MainActor in
      try? await self.flutterApi.onError(
        textureId: self.textureId,
        errorCode: "PLAYBACK_FAILED",
        errorMessage: error
      )
    }
  }

  // MARK: - Notifications to Flutter

  private func notifyPlaybackState(_ state: PlaybackState) {
    guard !isDisposed else { return }
    Task { @MainActor in
      try? await self.flutterApi.onPlaybackStateChanged(textureId: self.textureId, state: state)
    }
  }

  private func notifyPosition() {
    guard !isDisposed else { return }
    let curPos = getPosition()
    let dur = getDuration()
    let buffered = getBufferedPosition()
    Task { @MainActor in
      try? await self.flutterApi.onPositionChanged(
        textureId: self.textureId,
        positionMs: curPos,
        durationMs: dur,
        bufferedPositionMs: buffered
      )
    }
  }

  private func notifyVideoQualities() {
    guard !isDisposed else { return }
    let qualities = getVideoQualities()
    Task { @MainActor in
      try? await self.flutterApi.onVideoQualitiesChanged(
        textureId: self.textureId,
        qualities: qualities
      )
    }
  }

  // MARK: - Player Controls

  func play() {
    if getPosition() >= getDuration() && getDuration() > 0 {
      seekTo(positionMs: 0)
    }
    player.play()
    if playbackSpeed != 1.0 {
      player.rate = playbackSpeed
    }
    startDisplayLink()
  }

  func pause() {
    player.pause()
    stopDisplayLink()
  }

  func setSource(url: String) {
    stopDisplayLink()
    removeItemObservers()
    latestPixelBuffer = nil
    selectedQualityId = nil

    notifyPlaybackState(.buffering)

    loadMedia(url: url, autoPlay: true)
  }

  func seekTo(positionMs: Int64) {
    let targetTime = CMTime(value: positionMs, timescale: 1000)
    player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
      guard let self = self else { return }
      self.notifyPosition()
      self.registry.textureFrameAvailable(self.textureId)
    }
  }

  func setVolume(_ volume: Float) {
    player.volume = max(0.0, min(1.0, volume))
  }

  func setPlaybackSpeed(_ speed: Float) {
    let clamped = max(0.25, min(4.0, speed))
    self.playbackSpeed = clamped
    if player.timeControlStatus == .playing {
      player.rate = clamped
    }
  }

  func getDuration() -> Int64 {
    guard let item = currentItem else { return 0 }
    let dur = item.duration
    if dur.isNumeric && !dur.isIndefinite {
      let seconds = CMTimeGetSeconds(dur)
      return seconds > 0 ? Int64(seconds * 1000) : 0
    }
    return 0
  }

  func getPosition() -> Int64 {
    let current = player.currentTime()
    if current.isNumeric && !current.isIndefinite {
      let seconds = CMTimeGetSeconds(current)
      return seconds > 0 ? Int64(seconds * 1000) : 0
    }
    return 0
  }

  func getBufferedPosition() -> Int64 {
    guard let item = currentItem else { return 0 }
    guard let range = item.loadedTimeRanges.first?.timeRangeValue else { return 0 }
    let start = CMTimeGetSeconds(range.start)
    let duration = CMTimeGetSeconds(range.duration)
    let buffered = start + duration
    return buffered.isFinite && buffered > 0 ? Int64(buffered * 1000) : 0
  }

  // MARK: - Video Qualities (HLS ABR)

  func getVideoQualities() -> [VideoQuality] {
    guard let item = currentItem else { return [] }
    var qualities: [VideoQuality] = []

    if #available(iOS 15.0, *) {
      guard let urlAsset = item.asset as? AVURLAsset else { return [] }
      let variants = urlAsset.variants
      for (index, variant) in variants.enumerated() {
        let bitrate = Int64(variant.peakBitRate ?? variant.averageBitRate ?? 0)
        let size = variant.videoAttributes?.presentationSize ?? .zero
        let width = Int64(size.width)
        let height = Int64(size.height)
        let fps = variant.videoAttributes?.nominalFrameRate.map { Double($0) }
        let id = "\(index)"
        let label = height > 0 ? "\(height)p" : "Quality \(index + 1)"
        let isSelected = selectedQualityId == id

        qualities.append(
          VideoQuality(
            id: id,
            width: width,
            height: height,
            bitrate: bitrate,
            isSelected: isSelected,
            label: label,
            frameRate: fps
          )
        )
      }
    }
    return qualities
  }

  func setVideoQuality(qualityId: String) {
    selectedQualityId = qualityId
    guard let item = currentItem else { return }

    if qualityId == "auto" {
      item.preferredPeakBitRate = 0
      if #available(iOS 14.0, *) {
        item.preferredMaximumResolution = .zero
      }
    } else if #available(iOS 15.0, *),
      let urlAsset = item.asset as? AVURLAsset,
      let index = Int(qualityId),
      index < urlAsset.variants.count
    {
      let variant = urlAsset.variants[index]
      if let peak = variant.peakBitRate {
        item.preferredPeakBitRate = peak
      }
      if let size = variant.videoAttributes?.presentationSize, #available(iOS 14.0, *) {
        item.preferredMaximumResolution = size
      }
    }
    notifyVideoQualities()
  }

  // MARK: - Disposal

  func dispose() {
    guard !isDisposed else { return }
    isDisposed = true

    stopDisplayLink()
    stopTimeObserver()
    removeItemObservers()

    timeControlObserver?.invalidate()
    timeControlObserver = nil

    player.pause()
    player.replaceCurrentItem(with: nil)

    registry.unregisterTexture(textureId)
    latestPixelBuffer = nil
  }
}
