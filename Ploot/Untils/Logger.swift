//
//  Logger.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 24/10/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import Foundation

class Logger {
  private static var getTime: String {
    let date = Date()
    let calendar = Calendar.current

    let hour = calendar.component(.hour, from: date)
    let minutes = calendar.component(.minute, from: date)
    let seconds = calendar.component(.second, from: date)
    return "\(hour):\(minutes):\(seconds)"
  }

  static func info(_ text: String, from: AnyObject) {
    print("(\(getTime)) #info# \(from) - \(text)")
  }

  static func error(_ text: String, from: AnyObject) {
    print("(\(getTime)) #error# \(from) - \(text)")
  }
}
