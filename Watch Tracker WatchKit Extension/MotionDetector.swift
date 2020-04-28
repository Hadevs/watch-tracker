import UIKit
import CoreMotion

final class MotionDetector {
  private let motionManager = CMMotionManager()
  private let opQueue: OperationQueue = {
    let o = OperationQueue()
    o.name = "core-motion-updates"
    return o
  }()
  
  var motion: ((CMDeviceMotion) -> Void)? = nil
  private var shouldRestartMotionUpdates = false
  
  init() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(appDidEnterBackground),
                                           name: .NSExtensionHostDidEnterBackground,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(appDidBecomeActive),
                                           name: .NSExtensionHostDidBecomeActive,
                                           object: nil)
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self,
                                              name: .NSExtensionHostDidEnterBackground,
                                              object: nil)
    NotificationCenter.default.removeObserver(self,
                                              name: .NSExtensionHostDidBecomeActive,
                                              object: nil)
  }
  
  func start() {
    self.shouldRestartMotionUpdates = true
    self.restartMotionUpdates()
  }
  
  func stop() {
    self.shouldRestartMotionUpdates = false
    self.motionManager.stopDeviceMotionUpdates()
  }
  
  @objc private func appDidEnterBackground() {
    self.restartMotionUpdates()
  }
  
  @objc private func appDidBecomeActive() {
    self.restartMotionUpdates()
  }
  
  private func restartMotionUpdates() {
    guard self.shouldRestartMotionUpdates else { return }
    let interval: TimeInterval = 0.2
    motionManager.accelerometerUpdateInterval = interval
    motionManager.gyroUpdateInterval = interval
    motionManager.deviceMotionUpdateInterval = interval
    motionManager.magnetometerUpdateInterval = interval
    self.motionManager.stopDeviceMotionUpdates()
    self.motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: self.opQueue) { deviceMotion, error in
      guard let deviceMotion = deviceMotion else { return }
      self.motion?(deviceMotion)
    }
  }
}
