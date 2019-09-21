//
//  UIStateView.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 17/10/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import UIKit

class StateProgressView: UIProgressView {
  /// Update progress indicator
  public func updateProgress(_ value: Float) {
    UIView.animate(withDuration: 0.3) {
      self.progress = value

      if self.progress <= 0.3 {
        self.progressTintColor = UIColor.red
      }
      if self.progress > 0.3 {
        self.progressTintColor = UIColor(rgb: 0xB973FF)
      }
    }
  }
}
