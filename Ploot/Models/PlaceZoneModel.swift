//
//  PlaneModel.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 13/12/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import ARKit
import SceneKit

/// Use for create place zone indicator on ar scene
class PlaceZoneModel: SCNNode {
  let anchor: ARPlaneAnchor
  let planeGeometry: SCNPlane

  init(anchor: ARPlaneAnchor) {
    self.anchor = anchor
    planeGeometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
    super.init()
    configure()
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// Default configure material, size and position
  private func configure() {
    let material = SCNMaterial()

    material.diffuse.contents = UIImage(named: "placeZone")
    planeGeometry.materials = [material]

    geometry = planeGeometry
    position = SCNVector3(anchor.center.x, 0, anchor.center.z)
    transform = SCNMatrix4MakeRotation(Float(-Double.pi / 2), 1.0, 0.0, 0.0)
  }

  /// Update size and positions
  public func update(anchor: ARPlaneAnchor) {
    planeGeometry.width = CGFloat(anchor.extent.x)
    planeGeometry.height = CGFloat(anchor.extent.z)
    position = SCNVector3(anchor.center.x, 0, anchor.center.z)
  }
}
