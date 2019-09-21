//
//  PetViewModel.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 16/10/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import ARKit
import Foundation
import SceneKit

protocol PetPresenterDelegate {
  /// Run if changed pet states
  func updatedProgress(value: Float, type: PetStateUpdateTypes)

  /// Run if changed active event state
  func updatedActiveEventState(isActive: Bool)

  /// Hide event state control panel or show
  func updatePlacePetStatus(isPlaced: Bool)
}

class PetPresenter {
  /// Active pet on ar scene
  private(set) var activePet: PetModel?

  private(set) var friendPet: PetModel?

  /// Floor scene for pet
  private(set) var floorScene: FloorModel?

  /// Event pet is active
  public var isActiveEvent: Bool = false {
    didSet {
      guard let delegate = self.delegate else { return }
      delegate.updatedActiveEventState(isActive: isActiveEvent)
    }
  }

  /// Check pet is placing on ar scene
  public var isPetPlaced: Bool = false {
    didSet {
      guard let delegate = self.delegate else { return }
      delegate.updatePlacePetStatus(isPlaced: isPetPlaced)
    }
  }

  /// Pet is go to visit
  private(set) var isPetInVisit: Bool = false

  /// Callback UI delegate
  public var delegate: PetPresenterDelegate? {
    didSet {
      loadingPet()
      backgroundPetStateUpdate()
      backgroundUpdatePointsInVisits()
    }
  }

  /// Loading pet from core data
  public func loadingPet() {
    // Get pet from core data
    if let activePet = CoreDataManager.data.petModelFromData {
      loadingPet(petModel: activePet)
    }
  }

  /// Loading pet from model
  private func loadingPet(petModel: PetModel) {
    // Loading if pet is nil
    if self.activePet != nil { return }

    // Creates floor scene
    floorScene = FloorModel()

    // Get pet from core data
    self.activePet = petModel
    guard let activePet = self.activePet else { return }
    activePet.stateObserver = petStateObserver(value:type:)

    // Update pet states
    updatePetState()

    // Update decorations on floor
    updateDecorations()

    // If pet is dead - send notification to observer about is
    if activePet.isDead {
      petStateObserver(value: 0, type: .dead)
    }

    // Pet is not placing on ar scene
    isPetPlaced = false

    // Logger
    Logger.info("Loading pet", from: self)
  }

  /// Reloading pet model and scene
  public func clearPet() {
    guard let activePet = self.activePet else { return }

    // Save pet to core data
    CoreDataManager.data.savePetData(petModel: activePet)

    // Pet is not placing on scene
    isPetPlaced = false

    // Clear all scene models
    self.activePet = nil
    friendPet = nil
    floorScene = nil

    // Logger
    Logger.info("Clear pet data", from: self)
  }

  /// Hide or show pet and floor on scene
  public func visibleModels(_ isVisible: Bool) {
    guard
      let activePet = self.activePet,
      let floorScene = self.floorScene else { return }

    activePet.node.isHidden = !isVisible
    floorScene.node.isHidden = !isVisible
  }

  /// Place active pet on ar scene
  public func placePet(atPoint position: SCNVector3, on scene: SCNScene) {
    guard let activePet = self.activePet,
      let floorScene = self.floorScene else { return }

    // Start or stop pet sleeping
    if activePet.isSleep {
      if activePet.tired > 0.9 {
        activePet.isSleep = false
      } else {
        startPetAction(type: .sleep)
      }
    }

    // Add nodes in async thread
    DispatchQueue.global(qos: .utility).async {
      // Add floor to scene
      floorScene.node.position = position
      scene.rootNode.addChildNode(floorScene.node)

      // Add pet to scene
      activePet.node.position = position
      scene.rootNode.addChildNode(activePet.node)
    }

    // Pet is placing
    isPetPlaced = true

    // Play sound
    SoundPlayer.player.play(type: .place)
  }

  /// Place friend peers pet to active pet floor
  public func placeFriendPet(peerModel: PeerModel) {
    // Remove guest model from scene
    if (peerModel.params["isEnd"] as? Bool) != nil {
      self.friendPet?.node.isHidden = true
      self.friendPet = nil
    }

    // Check exist friend pet and delegate
    guard self.friendPet == nil else { return }

    // Parse params from peer model
    guard
      let name = peerModel.params["name"] as? String,
      let level = peerModel.params["level"] as? Int
    else { return }

    // Creates friend node and get floor scene
    guard
      let friendPet = PetModel(name: name, level: level),
      let floorScene = self.floorScene
    else { return }

    // Add friend pet to floor scene
    if let friendNode = floorScene.node.childNode(withName: "friend", recursively: true) {
      friendNode.addChildNode(friendPet.node)
      self.friendPet = friendPet

      // Friend pet animations
      startPetAnimation(friendPet, withKey: .sit, repeatCount: Float.greatestFiniteMagnitude)

      // Main effects
      startPetPartical(type: .friendSpawn, timeLife: 3)
      startPetAnimation(withKey: .jump)
      startPetJump()
      SoundPlayer.player.play(type: .place)
    }
  }

  /// Places product decoration on the scene
  public func placeDecoration(index: Int) {
    guard let activePet = self.activePet else { return }

    // Get a not purchased list of products
    let filterProducts = GlobalData.data.productsListInPetMenu.filter { product in
      !activePet.decorationsList.contains(product.name)
    }
    let product = filterProducts[index]

    guard activePet.points >= product.price else { return }

    activePet.decorationsList.append(product.name)
    activePet.points -= product.price
    updateDecorations()
  }

  /// Background pet state updater
  public func backgroundPetStateUpdate() {
    // Run again after timeout
    let timeout = UInt32(GlobalData.data.timeoutRemovePetState)
    DispatchQueue.syncTimeoutRun(timeout: timeout, handler: { [weak self] in
      self?.backgroundPetStateUpdate()
    })

    // Update
    updatePetState()

    // Send notificataion
    if let activePet = self.activePet {
      var params = [activePet.eat, activePet.happy, activePet.cleanness]

      if !activePet.isSleep {
        params.append(activePet.tired)
      }

      // Send notification
      NotificationManager.data.pushAttensionMe(params: params)

      // Save data
      CoreDataManager.data.savePetData(petModel: activePet)
    }

    // Logger
    Logger.info("Pet state update in background", from: self)
  }

  /// Background update pet points is pet go to visit
  private func backgroundUpdatePointsInVisits() {
    // Run again after timeout
    let timeout = UInt32(GlobalData.data.timeoutPeerAddBonus)
    DispatchQueue.syncTimeoutRun(timeout: timeout, handler: { [weak self] in
      self?.backgroundUpdatePointsInVisits()
    })

    guard let activePet = self.activePet, self.isPetInVisit else { return }

    activePet.points += 1
  }

  /// Update and remove/add pet states
  private func updatePetState() {
    guard let activePet = self.activePet, !activePet.isDead else { return }

    // Update default state
    activePet.eat -= GlobalData.data.countRemovePetStateBackground
    activePet.happy -= GlobalData.data.countRemovePetStateBackground
    activePet.cleanness -= GlobalData.data.countRemovePetStateBackground

    // Update points for update in UI
    activePet.points = Int(activePet.points)

    // Add/remove tired if pet sleeping or not
    if activePet.isSleep {
      activePet.tired += GlobalData.data.countRemovePetStateBackground * 2.0
    } else {
      activePet.tired -= GlobalData.data.countRemovePetStateBackground
    }

    // Update level state
    if let createDate = activePet.createDate {
      if GlobalData.data.isNewLevel(createDate: createDate, level: activePet.level) {
        activePet.level += 1
        // Add points if pet is level up
        activePet.points += GlobalData.data.countPointsLevelUp

        // Logger
        Logger.info("Pet is level up - \(activePet.level)", from: self)
      }
    }
  }

  /// Update visibility of decorations
  private func updateDecorations() {
    guard let activePet = self.activePet,
      let floorScene = self.floorScene else { return }

    for decoration in activePet.decorationsList {
      if let decorationNode = floorScene.node.childNode(withName: decoration, recursively: true) {
        decorationNode.isHidden = false
      }
    }
  }

  /// Update intensity and temperature of light on scene
  public func updateLightings(intensity: CGFloat, temperature: CGFloat) {
    guard let floorScene = self.floorScene else { return }

    // Update intensity in all lightings
    for lightNode in floorScene.lightingNodes {
      if let light = lightNode.light {
        light.intensity = intensity
        light.temperature = temperature
      }
    }
  }

  //

  // MARK: - State control

  //

  /// Pet state observer for update value
  private func petStateObserver(value: Float, type: PetStateUpdateTypes) {
    guard let activePet = self.activePet,
      let floorScene = self.floorScene else { return }

    switch type {
    case .sleep:
      // Go to sleep
      if !activePet.isSleep {
        stopAllPetAction()
      }
    case .feces:
      // Show or hide feces on floor scene
      floorScene.isShowFeces = activePet.isFeces
    case .level:
      // Start partials if level up
      stopAllPetAction()
      SoundPlayer.player.play(type: .level)
      startPetPartical(type: .level, timeLife: 8)
    default:
      break
    }

    // Update UI progress
    if let delegate = self.delegate {
      delegate.updatedProgress(value: value, type: type)
    }

    // Logger state
    Logger.info("Pet state observer \(type) value \(value)", from: self)
  }

  /// Menu start pet action
  public func startMenuAction(type: MenuActionTypes) {
    guard let activePet = self.activePet else { return }
    guard !isActiveEvent, !activePet.isDead else { return }

    // To wake up pet if start event
    if type != .sleep {
      activePet.isSleep = false
    }

    switch type {
    case .eat:
      activePet.eat += GlobalData.data.countAddPetState
      activePet.cleanness -= GlobalData.data.countAddPetState / 2.0
      activePet.points -= 1
      startPetAction(type: .eat)
      SoundPlayer.player.play(type: .eat)
    case .hand:
      activePet.happy += GlobalData.data.countAddPetState
      startPetAction(type: .sit)
      SoundPlayer.player.play(type: .laugh)
    case .play:
      // Not add happy if feces is exist
      if !activePet.isFeces {
        activePet.happy += GlobalData.data.countAddPetState * 1.5
        activePet.tired -= GlobalData.data.countAddPetState
      }

      startPetAction(type: .play)
      SoundPlayer.player.play(type: .play)
    case .clean:
      // Add happy if fecas is exists
      if activePet.isFeces {
        activePet.happy += GlobalData.data.countAddPetState
      }

      activePet.cleanness += GlobalData.data.countAddPetState * 2
      startPetPartical(type: .clean, timeLife: 4)
      SoundPlayer.player.play(type: .clean)
    case .sleep:
      if activePet.isSleep { return }
      activePet.isSleep = true
      startPetAction(type: .sleep)
      SoundPlayer.player.play(type: .sleep)
    }

    // Change status of access to event
    isActiveEvent = true

    // Activated pet event menu
    let timeout = UInt32(GlobalData.data.timeoutToNextPetEvent)
    DispatchQueue.syncTimeoutRun(timeout: timeout) { [weak self] in
      self?.isActiveEvent = false
    }
  }

  /// Start pet action - animation and partial
  private func startPetAction(type: PetActionTypes) {
    stopAllPetAction()

    switch type {
    case .idle:
      break
    case .eat:
      startPetAnimation(withKey: .eat)
      startPetPartical(type: .eat, timeLife: 4)
    case .play:
      startPetAnimation(withKey: .jump)
      startPetPartical(type: .play, timeLife: 3)
      startPetJump()
    case .clean:
      startPetPartical(type: .clean, timeLife: 4)
    case .sit:
      startPetAnimation(withKey: .sit)
      startPetPartical(type: .hand, timeLife: 3)
    case .sleep:
      startPetAnimation(withKey: .sleep, repeatCount: Float.greatestFiniteMagnitude)
      startPetPartical(type: .sleep, timeLife: 0)
    }
  }

  /// Stop all pet animations and partials
  private func stopAllPetAction() {
    guard let activePet = self.activePet else { return }

    activePet.node.removeAllParticleSystems()

    if let activeAnimationKey = activePet.activeAnimationKey {
      activePet.node.removeAnimation(forKey: activeAnimationKey, blendOutDuration: 0.3)
    }
  }

  //

  // MARK: - Animations

  //

  /// Rotate pet to camera position
  public func startPetRotate(to camera: ARCamera) {
    guard let activePet = self.activePet else { return }
    guard !activePet.isSleep, !activePet.isDead, !isActiveEvent else { return }

    let position = camera.eulerAngles
    let action = SCNAction.rotateTo(x: 0, y: CGFloat(position.y), z: 0, duration: 1)

    activePet.node.runAction(action)

    if let friendPet = self.friendPet {
      friendPet.node.runAction(action)
    }
  }

  /// Play animation by active pet
  private func startPetAnimation(withKey key: PetAnimationTypes, repeatCount: Float = 1) {
    guard let activePet = self.activePet else { return }

    startPetAnimation(activePet, withKey: key, repeatCount: repeatCount)
  }

  /// Play animation by pet model
  private func startPetAnimation(_ pet: PetModel, withKey key: PetAnimationTypes, repeatCount: Float = 1) {
    guard let animation = pet.animations[key.rawValue] else { return }

    animation.repeatCount = repeatCount
    pet.node.addAnimation(animation, forKey: key.rawValue)

    if let activeAnimationKey = pet.activeAnimationKey, activeAnimationKey != key.rawValue {
      pet.node.removeAnimation(forKey: activeAnimationKey, blendOutDuration: 0.5)
    }

    pet.activeAnimationKey = key.rawValue
  }

  /// Change pet position if start jump event
  private func startPetJump() {
    guard let activePet = self.activePet else { return }
    let height: Float = 0.04
    var position = activePet.node.position

    position.y += height

    var action = SCNAction.move(to: position, duration: 0.3)

    activePet.node.runAction(action) {
      position.y -= height
      action = SCNAction.move(to: position, duration: 1.2)
      activePet.node.runAction(action)
    }
  }

  //

  // MARK: - Particles

  //

  /// Add partical effect by name
  private func startPetPartical(type: ParticleTypes, timeLife: UInt32) {
    guard let floorScene = self.floorScene else { return }
    guard let partial = SCNParticleSystem(named: type.rawValue, inDirectory: "art.scnassets/partials") else {
      Logger.error("Not found partical \(type.rawValue)", from: self)
      return
    }

    floorScene.node.removeAllParticleSystems()
    floorScene.node.addParticleSystem(partial)

    // End partical after timeout
    DispatchQueue.syncTimeoutRun(timeout: timeLife) {
      guard timeLife != 0 else { return }
      floorScene.node.removeParticleSystem(partial)
    }
  }
}
