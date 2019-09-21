//
//  WelcomeController.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 25/10/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import UIKit

class WelcomeController: UIViewController {
  /// Presenter
  private(set) lazy var presenter = WelcomePresenter()

  // UI
  @IBOutlet var buttonAccessNotifications: UIButton!
  @IBOutlet var buttonAccessCamera: UIButton!

  /// Request permission for notifications
  @IBAction func buttonRequestNotification(_: UIButton) {
    presenter.requestAccessToNotifications()
  }

  /// Request permission for camera
  @IBAction func buttonRequestCamera(_: UIButton) {
    presenter.requestAccessToCamera()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Setting presenter
    presenter.delegate = self
    presenter.checkAllAccess()
  }

  /// Show alert about not access to use camera
  private func alertNotAccessToCamera() {
    let title = NSLocalizedString("Camera", comment: "Access to camera")
    let message = NSLocalizedString("Please give access to camera in settings your phone for use AR in application.", comment: "Access to camera")
    let actionTitle = NSLocalizedString("Ok", comment: "Access to camera action")
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let action = UIAlertAction(title: actionTitle, style: .default, handler: nil)

    alert.addAction(action)
    present(alert, animated: true, completion: nil)
  }
}

// MARK: - WelcomePresenterDelegate

extension WelcomeController: WelcomePresenterDelegate {
  func notAccessToCamera() {
    alertNotAccessToCamera()
  }

  func updateAccess(to: AccessTypes, granted: Bool) {
    switch to {
    case .notifications:
      buttonAccessNotifications.isAccess = !granted
    case .camera:
      buttonAccessCamera.isAccess = !granted

      // If exist access and pet is created
      if granted, presenter.isPetCreated {
        performSegue(withIdentifier: "Scene", sender: self)
      }

      // If exist access and pet is not created
      if granted, !presenter.isPetCreated {
        performSegue(withIdentifier: "Store", sender: self)
      }
    }
  }
}
