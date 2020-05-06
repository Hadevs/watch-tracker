//
//  InterfaceController.swift
//  Watch Tracker WatchKit Extension
//
//  Created by Ghost on 10.04.2020.
//  Copyright © 2020 Hadevs. All rights reserved.
//

import WatchKit
import Foundation
import CoreMotion
import HealthKit


let detector = MotionDetector()

class InterfaceController: WKInterfaceController, WKExtendedRuntimeSessionDelegate, CLLocationManagerDelegate {
  
  var dicts: [[String: String]] = [] {
    didSet {
      label.setText("Stack size: \(dicts.count)")
    }
  }
  func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
    print("error runtime: \(error)")
  }
  
  func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
    print("Extended session started")
  }
  
  func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
    print("Extended will expire")
  }
  
  @IBOutlet private weak var label: WKInterfaceLabel!
  @IBOutlet private weak var button: WKInterfaceButton!

  var prevText: String?
  let timer = RepeatingTimer(timeInterval: 1)
  var session: WKExtendedRuntimeSession!
  
  private let player = WKAudioFilePlayer(playerItem: WKAudioFilePlayerItem(asset: WKAudioFileAsset(url: URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3")!, title: "Hello", albumTitle: "Album title", artist: "Artist!")))
  
  private let locationManager = CLLocationManager()
  
  override func awake(withContext context: Any?) {
    super.awake(withContext: context)

    detector.motion = processDeviceMotion
    detector.start()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
      self.session = WKExtendedRuntimeSession()
      self.session.delegate = self
      self.session.start()
      self.player.play()
    }
    
    timer.resume()

    startWorkoutSession()
    initLocationManager()
  }
  
  private func initLocationManager() {
    let locationManager = CLLocationManager()
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
    
    locationManager.allowsBackgroundLocationUpdates = true
    
    locationManager.distanceFilter = kCLDistanceFilterNone
    if #available(watchOSApplicationExtension 3.0, *) {
      locationManager.startUpdatingLocation()
    }
  }
  
  private func startWorkoutSession() {
    let session = try! HKWorkoutSession(healthStore: .init(), configuration: .init())
    session.prepare()
    session.startActivity(with: Date())
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
  }
  
  @IBAction private func buttonClicked() {
    startSendingRequests()
  }
  
  private func startSendingRequests() {
    button.setEnabled(false)
    button.setAlpha(0.5)
    var request = URLRequest(url: URL(string: "https://we.today/watches?data=ok")!)
    request.httpMethod = "POST"
    let dict = ["data": dicts]
    request.httpBody = try? JSONEncoder().encode(dict)
    URLSession.shared.dataTask(with: request) { (data, response, error) in
      print("Request sent")
      self.button.setEnabled(true)
      self.button.setAlpha(1)
    }.resume()
    dicts = []
    
  }
  
  func processDeviceMotion(_ deviceMotion: CMDeviceMotion) {
    // 1. These strings are to show on the UI. Trying to fit
    // x,y,z values for the sensors is difficult so we’re
    // just going with one decimal point precision.
    let gravityStr = String(format: "X: %.1f Y: %.1f Z: %.1f" ,
                            deviceMotion.gravity.x,
                            deviceMotion.gravity.y,
                            deviceMotion.gravity.z)
    let userAccelStr = String(format: "X: %.1f Y: %.1f Z: %.1f" ,
                              deviceMotion.userAcceleration.x,
                              deviceMotion.userAcceleration.y,
                              deviceMotion.userAcceleration.z)
    let rotationRateStr = String(format: "X: %.1f Y: %.1f Z: %.1f" ,
                                 deviceMotion.rotationRate.x,
                                 deviceMotion.rotationRate.y,
                                 deviceMotion.rotationRate.z)
    let attitudeStr = String(format: "r: %.1f p: %.1f y: %.1f" ,
                             deviceMotion.attitude.roll,
                             deviceMotion.attitude.pitch,
                             deviceMotion.attitude.yaw)
    
    dicts.append([
      "gravity": gravityStr,
      "gravityAcceleration": userAccelStr,
      "rotationRate": rotationRateStr,
      "attitude": attitudeStr,
      "time": "\(deviceMotion.timestamp)"
    ])
    print(deviceMotion.timestamp)
    
  }
  
  override func willActivate() {
    // This method is called when watch view controller is about to be visible to user
    super.willActivate()
  }
  
  override func didDeactivate() {
    // This method is called when watch view controller is no longer visible
    super.didDeactivate()
  }
  
}

class RepeatingTimer {
  let timeInterval: TimeInterval
  
  init(timeInterval: TimeInterval) {
    self.timeInterval = timeInterval
  }
  
  private lazy var timer: DispatchSourceTimer = {
    let t = DispatchSource.makeTimerSource()
    t.schedule(deadline: .now() + self.timeInterval, repeating: self.timeInterval)
    t.setEventHandler(handler: { [weak self] in
      self?.eventHandler?()
    })
    return t
  }()
  
  var eventHandler: (() -> Void)?
  
  private enum State {
    case suspended
    case resumed
  }
  
  private var state: State = .suspended
  
  deinit {
    timer.setEventHandler {}
    timer.cancel()
    resume()
    eventHandler = nil
  }
  
  func resume() {
    if state == .resumed {
      return
    }
    state = .resumed
    timer.resume()
  }
  
  func suspend() {
    if state == .suspended {
      return
    }
    state = .suspended
    timer.suspend()
  }
}
