//
//  FloorModel.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 29/10/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import ARKit
import Foundation
import SceneKit

class FloorModel {
  /// Main floor node
  public let node: SCNNode

  /// Feceses node contain feces nodes
  public let fecesesNode: SCNNode

  /// Lighting node
  public let lightingNodes: [SCNNode]

  /// Visible feces on floor scene
  public var isShowFeces: Bool = false {
    didSet {
      fecesesNode.isHidden = !isShowFeces
    }
  }

  init?() {
    guard let floorScene = SCNScene(named: "art.scnassets/floor.scn"),
      let fecesesNode = floorScene.rootNode.childNode(withName: "feceses", recursively: true) else {
      return nil
    }

    // Loading all lightings from scene
    let lightingNodes = floorScene.rootNode.childNodes { (node, _) -> Bool in
      node.name == "lighting"
    }

    // Default init params
    node = floorScene.rootNode
    self.lightingNodes = !lightingNodes.isEmpty ? lightingNodes : []
    self.fecesesNode = fecesesNode
    self.fecesesNode.isHidden = false

    // Init partials for feces node
    initPartialInFeceses()
  }

  /// Init partial system on feceses
  private func initPartialInFeceses() {
    guard let partial = SCNParticleSystem(named: "feces", inDirectory: "art.scnassets/partials") else {
      Logger.error("Not found partical feces", from: self)
      return
    }

    for feces in fecesesNode.childNodes {
      feces.addParticleSystem(partial)
    }
  }
}
