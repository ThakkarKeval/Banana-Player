import Flutter
import UIKit

public class BananaPlayerPlugin: NSObject, FlutterPlugin, BananaPlayerHostApi {
  private let registrar: FlutterPluginRegistrar
  private let flutterApi: BananaPlayerFlutterApi
  private var players: [Int64: BananaPlayer] = [:]

  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
    self.flutterApi = BananaPlayerFlutterApi(binaryMessenger: registrar.messenger())
    super.init()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = BananaPlayerPlugin(registrar: registrar)
    registrar.publish(instance)
    BananaPlayerHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    BananaPlayerHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: nil)
    for (_, player) in players {
      player.dispose()
    }
    players.removeAll()
  }

  // MARK: - BananaPlayerHostApi

  private func playerOrThrow(_ textureId: Int64) throws -> BananaPlayer {
    guard let player = players[textureId] else {
      throw PigeonError(
        code: "player_not_found",
        message: "No active player found with textureId \(textureId)",
        details: nil
      )
    }
    return player
  }

  private func invalidArgument(_ message: String) -> PigeonError {
    PigeonError(code: "invalid_argument", message: message, details: nil)
  }

  func create(config: PlayerConfig) throws -> Int64 {
    guard !config.url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw invalidArgument("Media URL cannot be blank")
    }
    guard config.volume.isFinite && (0.0...1.0).contains(config.volume) else {
      throw invalidArgument("Volume must be finite and between 0 and 1")
    }
    let player = BananaPlayer(
      config: config,
      registry: registrar.textures(),
      flutterApi: flutterApi,
      registrar: registrar
    )
    players[player.textureId] = player
    return player.textureId
  }

  func play(textureId: Int64) throws {
    try playerOrThrow(textureId).play()
  }

  func pause(textureId: Int64) throws {
    try playerOrThrow(textureId).pause()
  }

  func setSource(textureId: Int64, url: String) throws {
    let player = try playerOrThrow(textureId)
    guard !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw invalidArgument("Media URL cannot be blank")
    }
    player.setSource(url: url)
  }

  func seekTo(textureId: Int64, positionMs: Int64) throws {
    try playerOrThrow(textureId).seekTo(positionMs: positionMs)
  }

  func setVolume(textureId: Int64, volume: Double) throws {
    let player = try playerOrThrow(textureId)
    guard volume.isFinite else {
      throw invalidArgument("Volume must be finite")
    }
    player.setVolume(Float(volume))
  }

  func getDuration(textureId: Int64) throws -> Int64 {
    try playerOrThrow(textureId).getDuration()
  }

  func getPosition(textureId: Int64) throws -> Int64 {
    try playerOrThrow(textureId).getPosition()
  }

  func getVideoQualities(textureId: Int64) throws -> [VideoQuality] {
    try playerOrThrow(textureId).getVideoQualities()
  }

  func setVideoQuality(textureId: Int64, qualityId: String) throws {
    let player = try playerOrThrow(textureId)
    let availableQualityIds = player.getVideoQualities().map(\.id)
    guard qualityId == "auto" || availableQualityIds.contains(qualityId) else {
      throw invalidArgument("Unknown video quality ID: \(qualityId)")
    }
    player.setVideoQuality(qualityId: qualityId)
  }

  func setPlaybackSpeed(textureId: Int64, speed: Double) throws {
    let player = try playerOrThrow(textureId)
    guard speed.isFinite && speed > 0 else {
      throw invalidArgument("Playback speed must be finite and greater than 0")
    }
    player.setPlaybackSpeed(Float(speed))
  }

  func getSubtitleTracks(textureId: Int64) throws -> [SubtitleTrack] {
    try playerOrThrow(textureId).getSubtitleTracks()
  }

  func setSubtitleTrack(textureId: Int64, trackId: String) throws {
    try playerOrThrow(textureId).setSubtitleTrack(trackId: trackId)
  }

  func dispose(textureId: Int64) throws {
    let player = try playerOrThrow(textureId)
    players.removeValue(forKey: textureId)
    player.dispose()
  }
}
