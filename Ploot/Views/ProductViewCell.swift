//
//  ProductViewCell.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 25/11/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import UIKit

class ProductViewCell: UITableViewCell {
  /// UI
  @IBOutlet var labelName: UILabel!
  @IBOutlet var labelPoints: UILabel!
  @IBOutlet var imagePoints: UIImageView!

  /// Initialing cell view and binding function for handling touch
  func initCell(product: ProductModel) {
    let selectedView = UIView()

    // Setting selected color
    selectedView.backgroundColor = UIColor(rgb: 0xF1DCFF)
    selectedBackgroundView = selectedView

    // Setting content
    labelName.text = product.visibleName
    labelPoints.text = "\(product.price)"
  }
}
