//
//  InformPeerController.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 05/02/2019.
//  Copyright © 2019 Aleksey Pleshkov. All rights reserved.
//

import UIKit

class InformPeerController: UIViewController {
  /// For close this controller in pet controller
  var actionHandler: (() -> Void)?

  // UI
  @IBOutlet var buttonStartVisit: UIButton!

  /// Start share session and close controller
  @IBAction func buttonStartVisit(_: Any) {
    guard let actionHandler = self.actionHandler else { return }

    actionHandler()
  }
}
