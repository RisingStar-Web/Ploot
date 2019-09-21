//
//  LevelUpController.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 22/12/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import UIKit

class LevelUpController: UIViewController {
  /// Closure for close window modal
  public var closeHandler: (() -> Void)?

  /// Event close modal by button
  @IBAction func closeModal(_: Any) {
    guard let closeClosure = self.closeHandler else { return }
    closeClosure()
  }
}
