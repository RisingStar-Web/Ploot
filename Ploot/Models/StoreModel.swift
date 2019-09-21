//
//  StoreModel.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 26/10/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import Foundation

class StoreModel {
  let name: String
  let visibleName: String
  var isSelected = false

  init(name: String, visibleName: String) {
    self.name = name
    self.visibleName = visibleName
  }
}
