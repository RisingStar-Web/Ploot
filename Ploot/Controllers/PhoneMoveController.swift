//
//  PhoneMoveController.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 08/12/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import UIKit

class PhoneMoveController: UIViewController {
  /// UI
  @IBOutlet var imagePhone: UIImageView!

  override func viewDidLoad() {
    super.viewDidLoad()

    // Init translate in image phone
    let translate = imagePhone.transform.translatedBy(x: 60, y: 0)
    imagePhone.transform = translate

    startAnimation()
  }

  /// Translate phone animation
  private func startAnimation() {
    UIView.animate(withDuration: 1, animations: {
      let translate = self.imagePhone.transform.translatedBy(x: -120, y: 0)
      self.imagePhone.transform = translate
    }, completion: { _ in

      UIView.animate(withDuration: 1, animations: {
        let translate = self.imagePhone.transform.translatedBy(x: 120, y: 0)
        self.imagePhone.transform = translate
      }, completion: { _ in

        // Restart animation
        self.startAnimation()
      })
    })
  }
}
