//
//  MenuItemModel.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 16/10/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import Foundation

/// Menu touch event types for pet.
/// String value for get images in assets
enum MenuActionTypes: String, CaseIterable {
  case eat = "menu-eat"
  case hand = "menu-hand"
  case play = "menu-play"
  case clean = "menu-clean"
  case sleep = "menu-sleep"
}
