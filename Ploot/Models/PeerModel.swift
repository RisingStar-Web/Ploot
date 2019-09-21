//
//  PeerModel.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 04/02/2019.
//  Copyright © 2019 Aleksey Pleshkov. All rights reserved.
//

import Foundation

/// Model for send by multipeer connectivity
class PeerModel: NSObject, NSSecureCoding {
  static var supportsSecureCoding: Bool {
    return true
  }

  let params: [String: Any]

  init(params: [String: Any]) {
    self.params = params
  }

  required init?(coder aDecoder: NSCoder) {
    guard let params = aDecoder.decodeObject(forKey: "params") as? [String: Any] else {
      return nil
    }

    self.params = params

    super.init()
  }

  func encode(with aCoder: NSCoder) {
    aCoder.encode(params, forKey: "params")
  }
}
