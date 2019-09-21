//
//  StoreCellView.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 26/10/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import UIKit

class StoreViewCell: UITableViewCell {
  /// UI
  @IBOutlet var labelName: UILabel!

  /// Initialing cell view and binding function for handling touch
  func initCell(petName: String) {
    let selectedView = UIView()

    // Setting selected color
    selectedView.backgroundColor = UIColor(rgb: 0xF1DCFF)
    selectedBackgroundView = selectedView

    // Setting name
    labelName.text = petName
  }
}
