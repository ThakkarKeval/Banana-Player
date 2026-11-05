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

  func create(config: PlayerConfig) throws -> Int64 {
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
    guard let player = players[textureId] else {
      throw PigeonError(code: "NOT_FOUND", message: "Player \(textureId) not found", details: nil)
    }
    player.play()
  }

  func pause(textureId: Int64) throws {
    guard let player = players[textureId] else {
      throw PigeonError(code: "NOT_FOUND", message: "Player \(textureId) not found", details: nil)
    }
    player.pause()
  }

  func setSource(textureId: Int64, url: String) throws {
    guard let player = players[textureId] else {
      throw PigeonError(code: "NOT_FOUND", message: "Player \(textureId) not found", details: nil)
    }
    player.setSource(url: url)
  }

  func seekTo(textureId: Int64, positionMs: Int64) throws {
    guard let player = players[textureId] else {
      throw PigeonError(code: "NOT_FOUND", message: "Player \(textureId) not found", details: nil)
    }
    player.seekTo(positionMs: positionMs)
  }

  func setVolume(textureId: Int64, volume: Double) throws {
    guard let player = players[textureId] else {
      throw PigeonError(code: "NOT_FOUND", message: "Player \(textureId) not found", details: nil)
    }
    player.setVolume(Float(volume))
  }

  func getDuration(textureId: Int64) throws -> Int64 {
    return players[textureId]?.getDuration() ?? 0
  }

  func getPosition(textureId: Int64) throws -> Int64 {
    return players[textureId]?.getPosition() ?? 0
  }

  func getVideoQualities(textureId: Int64) throws -> [VideoQuality] {
    return players[textureId]?.getVideoQualities() ?? []
  }

  func setVideoQuality(textureId: Int64, qualityId: String) throws {
    guard let player = players[textureId] else {
      throw PigeonError(code: "NOT_FOUND", message: "Player \(textureId) not found", details: nil)
    }
    player.setVideoQuality(qualityId: qualityId)
  }

  func setPlaybackSpeed(textureId: Int64, speed: Double) throws {
    guard let player = players[textureId] else {
      throw PigeonError(code: "NOT_FOUND", message: "Player \(textureId) not found", details: nil)
    }
    player.setPlaybackSpeed(Float(speed))
  }

  func dispose(textureId: Int64) throws {
    if let player = players.removeValue(forKey: textureId) {
      player.dispose()
    }
  }
}
