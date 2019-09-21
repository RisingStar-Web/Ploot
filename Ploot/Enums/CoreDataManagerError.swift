//
//  CoreDataManagerError.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 05/12/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import Foundation

/// Errors for throws core data
enum CoreDataManagerError: Error {
  case noResult
  case noKey
  case noMainEntity
  case noContext
}
