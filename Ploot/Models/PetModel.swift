//
//  Pet.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 08/10/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import ARKit

typealias PetStateObserver = (Float, PetStateUpdateTypes) -> Void

class PetModel {
  /// Pet name
  public let name: String

  /// Last update in core data
  public var lastUpdate: Date?

  /// Last update points in core data
  public var lastPointsUpdate: Date?

  /// Date of creating pet
  public var createDate: Date?

  /// Animations list
  private(set) var animations: [String: CAAnimation] = [:]

  /// Active animation key for remove before change animation
  public var activeAnimationKey: String?

  /// Pet AR node
  public let node: SCNReferenceNode

  /// Pet level
  public var level: Int = 1 {
    didSet {
      if level <= 0 { level = 1 }

      // Change node size
      let petLevelSize = Float(0.001) * Float(level)
      let petSize = 0.02 + petLevelSize

      node.scale = SCNVector3(petSize, petSize, petSize)

      // Notify observer
      guard let observer = self.stateObserver, self.level != oldValue else { return }
      observer(Float(level), .level)
    }
  }

  /// Indicator of eat
  public var eat: Float = 0.5 {
    didSet {
      if eat <= 0 {
        eat = 0
        isDead = true
      }
      if eat > 1 { eat = 1 }

      guard let observer = self.stateObserver else { return }
      observer(eat, .eat)
    }
  }

  /// Indicator of tired
  public var tired: Float = 0.5 {
    didSet {
      if tired <= 0 {
        tired = 0
        isDead = true
      }
      if tired >= 1 {
        tired = 1
        isSleep = false
      }

      guard let observer = self.stateObserver else { return }
      observer(tired, .tired)
    }
  }

  /// Indicator of happiness
  public var happy: Float = 0.5 {
    didSet {
      if happy <= 0 {
        happy = 0
        isDead = true
      }
      if isFeces, happy > 0.5 {
        happy = 0.5
      }
      if happy > 1 { happy = 1 }

      guard let observer = self.stateObserver else { return }
      observer(happy, .happy)
    }
  }

  // Indicator of points
  public var points: Int = GlobalData.data.countPointsOneDay {
    didSet {
      if points < 0 { points = 0 }

      guard let observer = self.stateObserver else { return }
      observer(Float(points), .point)
    }
  }

  // Size pet of day from birth
  public var daysFromBirth: Int = 0

  // Buy decorations list
  public var decorationsList: [String] = []

  /// Indicator of feces
  private(set) var isFeces: Bool = false
  public var cleanness: Float = 1 {
    didSet {
      if cleanness < 0 { cleanness = 0 }
      if cleanness > 1 { cleanness = 1 }

      if cleanness < 0.5 { isFeces = true }
      if cleanness >= 0.5 { isFeces = false }

      guard let observer = self.stateObserver else { return }
      observer(0, .feces)
      observer(cleanness, .cleanness)
    }
  }

  /// Pet is dead
  public var isDead: Bool = false {
    didSet {
      guard let observer = self.stateObserver else { return }
      observer(0, .dead)
    }
  }

  /// Pet is sleeping
  public var isSleep: Bool = false {
    didSet {
      guard let observer = self.stateObserver else { return }
      observer(0, .sleep)
    }
  }

  /// State observer for presenter
  public var stateObserver: PetStateObserver?

  /// Init pet model by dae file
  init?(name: String, level: Int = 1) {
    guard let modelUrl = Bundle.main.url(forResource: "art.scnassets/\(name)/idle", withExtension: "dae"),
      let node = SCNReferenceNode(url: modelUrl) else { return nil }

    self.node = node
    self.node.castsShadow = true
    self.node.load()
    self.level = level
    self.name = name

    loadMaterials()
    loadAnimations()

    // Update pet size for level size
    let baseScale = self.node.scale.y
    let petLevelSize = Float(0.001) * Float(level)
    let petSize = baseScale + petLevelSize

    self.node.scale = SCNVector3(petSize, petSize, petSize)
  }

  /// Loading material for model node
  private func loadMaterials() {
    // Get material
    let material = SCNMaterial()
    guard let texture = UIImage(named: "art.scnassets/\(self.name)/\(self.name).jpg") else {
      Logger.error("Texture \(name) not found", from: self)
      return
    }
    material.diffuse.contents = texture

    // Get model and set material
    if let model = self.node.childNode(withName: "Model", recursively: false),
      let modelGeometry = model.geometry {
      modelGeometry.materials = [material]
    }
  }

  /// Loading animatios from other dae models
  private func loadAnimations() {
    for key in PetAnimationTypes.allCases {
      guard let sceneURL = Bundle.main.url(forResource: "art.scnassets/\(self.name)/\(key.rawValue)", withExtension: "dae") else {
        Logger.error("Animation \(key.rawValue) in \(name) not found", from: self)
        return
      }
      let sceneSource = SCNSceneSource(url: sceneURL, options: nil)

      if let animationObject = sceneSource?.entryWithIdentifier("animation", withClass: CAAnimation.self) {
        animationObject.repeatCount = 1
        animationObject.fadeInDuration = 0.3
        animationObject.fadeOutDuration = 0.3
        animations[key.rawValue] = animationObject
      }
    }
  }
}
