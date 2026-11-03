import Flutter
import UIKit
import XCTest

@testable import banana_player

class RunnerTests: XCTestCase {

  func testPluginInstantiation() {
    let plugin = BananaPlayerPlugin()
    XCTAssertNotNil(plugin)
  }

}
