//
//  UIButton.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 25/11/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import UIKit

extension UIButton {
  @IBInspectable var isAccess: Bool {
    get {
      return isEnabled
    }
    set {
      isEnabled = newValue
      alpha = newValue ? 1 : 0.3
    }
  }
}
