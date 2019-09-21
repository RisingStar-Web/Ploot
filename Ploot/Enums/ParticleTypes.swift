//
//  ParticleTypes.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 24/10/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import Foundation

/// Particles effects list
enum ParticleTypes: String, CaseIterable {
  case eat
  case sleep
  case clean
  case hand
  case play
  case level
  case friendSpawn = "friend-spawn"
}
