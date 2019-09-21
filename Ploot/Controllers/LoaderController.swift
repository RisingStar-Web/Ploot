//
//  LoaderController.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 10/11/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import UIKit

class LoaderController: UIViewController {
  /// Loading indicator
  @IBOutlet var imageLoader: UIImageView!

  override func viewDidLoad() {
    super.viewDidLoad()
    rotationLoaderIndicator()
  }

  /// Infinite rotation image indicator
  private func rotationLoaderIndicator() {
    UIView.animate(withDuration: 1, delay: 0, options: UIView.AnimationOptions.curveLinear, animations: {
      let rotation = self.imageLoader.transform.rotated(by: CGFloat.pi)
      self.imageLoader.transform = rotation
    }, completion: { _ in
      self.rotationLoaderIndicator()
    })
  }
}
