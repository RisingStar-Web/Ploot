//
//  DispatchQueue.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 28/10/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import Foundation

extension DispatchQueue {
  /// Run sync handler after timeout
  public static func syncTimeoutRun(timeout: UInt32, handler: @escaping () -> Void) {
    DispatchQueue.global(qos: .background).async {
      sleep(timeout)

      DispatchQueue.main.sync {
        handler()
      }
    }
  }
}
