//
//  PeerController.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 05/02/2019.
//  Copyright © 2019 Aleksey Pleshkov. All rights reserved.
//

import UIKit

class PeerController: UIViewController {
  /// For close this controller in pet controller
  var actionHandler: (() -> Void)?

  /// Event of end peer session
  @IBAction func buttonEndVisit(_: Any) {
    guard let actionHandler = self.actionHandler else { return }

    actionHandler()
  }
}
