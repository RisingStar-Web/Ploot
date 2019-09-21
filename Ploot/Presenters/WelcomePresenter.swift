//
//  WelcomePresenter.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 05/01/2019.
//  Copyright © 2019 Aleksey Pleshkov. All rights reserved.
//

import AVFoundation
import Foundation
import UserNotifications

protocol WelcomePresenterDelegate {
  /// Update access to notifications
  func updateAccess(to: AccessTypes, granted: Bool)

  /// Permission to camera is block
  func notAccessToCamera()
}

class WelcomePresenter {
  /// Delegate
  var delegate: WelcomePresenterDelegate?

  /// Check is created pet
  let isPetCreated: Bool

  init() {
    isPetCreated = CoreDataManager.data.petModelFromData != nil
  }

  /// Request to get access to notificatons
  public func requestAccessToNotifications() {
    guard let delegate = self.delegate else { return }

    DispatchQueue.main.async {
      let center = UNUserNotificationCenter.current()
      center.requestAuthorization(options: [.alert, .sound]) { granted, _ in

        DispatchQueue.main.sync {
          delegate.updateAccess(to: .notifications, granted: granted)
        }
      }
    }
  }

  /// Request to get access to camera
  public func requestAccessToCamera() {
    guard let delegate = self.delegate else { return }

    DispatchQueue.main.async {
      AVCaptureDevice.requestAccess(for: AVMediaType.video) { granted in

        DispatchQueue.main.sync {
          delegate.updateAccess(to: .camera, granted: granted)

          if !granted {
            delegate.notAccessToCamera()
          }
        }
      }
    }
  }

  /// Check all access
  public func checkAllAccess() {
    guard let delegate = delegate else { return }
    let center = UNUserNotificationCenter.current()

    // Check access to notifications
    DispatchQueue.main.async {
      center.getNotificationSettings(completionHandler: { settings in
        let grantedAccess = settings.authorizationStatus == .authorized

        DispatchQueue.main.sync {
          delegate.updateAccess(to: .notifications, granted: grantedAccess)
        }
      })
    }

    // Check access to camera
    let cameraGrantedAccess = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    delegate.updateAccess(to: .camera, granted: cameraGrantedAccess)
  }
}
