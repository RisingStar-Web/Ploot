//
//  PetViewController.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 08/10/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import ARKit
import MultipeerConnectivity
import SceneKit
import UIKit
import UIMenuScroll

class PetController: UIViewController {
  /// Pet presenter
  private(set) lazy var petPresenter = PetPresenter()
  private(set) lazy var multipeerSession = MultipeerSession()

  /// Place zones
  private var placeZones: [PlaceZoneModel] = []

  /// Modals window
  private(set) var petMenuModal: ModalWindow?
  private(set) var deadMenuModal: ModalWindow?
  private(set) var phoneMoveModal: ModalWindow?
  private(set) var levelUpModal: ModalWindow?
  private(set) var informModal: ModalWindow?
  private(set) var informPeerModal: ModalWindow?
  private(set) var peerModal: ModalWindow?

  /// Last update ligthings
  private var lastIntensityLightings: CGFloat = 0

  /// UI's
  @IBOutlet var sceneView: ARSCNView!
  @IBOutlet var menuScroll: UIMenuScrollView!
  @IBOutlet var progressEat: StateProgressView!
  @IBOutlet var progressTired: StateProgressView!
  @IBOutlet var progressHappy: StateProgressView!
  @IBOutlet var progressCleanness: StateProgressView!
  @IBOutlet var labelPoints: UILabel!
  @IBOutlet var labelPlaceHelp: UILabel!

  /// Open pet menu modal
  @IBAction func openPetMenu(sender _: UIButton) {
    guard let petMenuModal = self.petMenuModal,
      let petMenuController = petMenuModal.childController as? PetMenuController else { return }

    // Update petMenuController data and show modal
    petMenuController.updateUIData()
    petMenuModal.isShow = true
  }

  /// Open information modal
  @IBAction func openInformModal(_: UIButton) {
    showInformModal()
  }

  /// Share active pet session to friends
  @IBAction func openPeerModal(_: Any) {
    showInformPeerModal()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configure()
  }

  private func configure() {
    // Scene view configure
    sceneView.delegate = self
    sceneView.session.delegate = self
    sceneView.scene = SCNScene()

    #if DEBUG
      sceneView.showsStatistics = true
      sceneView.debugOptions = [.showFeaturePoints]
    #endif

    // Setup menu scroll
    menuScroll.delegate = self
    menuScroll.spacing = 10.0

    // Default setups
    setupGestures()
    setupModals()
    setupObservers()

    // Setup presenter
    petPresenter.delegate = self

    // Multipeer session
    multipeerSession.delegate = self

    // Open phone move modal
    showPhoneMoveModal()
  }

  /// Event to hide or change focus app
  @objc func willResignActiveNotification() {
    // Clear all "place zone" indicators
    for placeZone in placeZones {
      sceneView.session.remove(anchor: placeZone.anchor)
    }
    placeZones.removeAll()

    // Clear scene and pet
    sceneView.scene = SCNScene()
    petPresenter.clearPet()
    multipeerSession.stopSession()
    multipeerSession.stopSearchPeer()
  }

  /// Event to reopen application
  @objc func didBecomeActiveNotification() {
    // Configure ar session
    setupSession()

    // Loading pet
    petPresenter.loadingPet()

    // Open phone move modal
    showPhoneMoveModal()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    setupSession()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    sceneView.session.pause()
  }

  /// Configure ar session
  private func setupSession() {
    let configuration = ARWorldTrackingConfiguration()
    configuration.planeDetection = .horizontal
    sceneView.session.run(configuration)
  }

  /// Reset AR session for plane detection
  private func resetSession() {
    if let configuration = sceneView.session.configuration as? ARWorldTrackingConfiguration {
      configuration.planeDetection = []
      sceneView.session.run(configuration)
    }
  }

  /// Initial setup observers
  private func setupObservers() {
    // Add observer for hide or change focus application
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(willResignActiveNotification),
      name: UIApplication.willResignActiveNotification,
      object: nil
    )

    // Add observer for reopen application
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(didBecomeActiveNotification),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )

    // Observer for change ambient light
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(updateLighting),
      name: nil,
      object: sceneView.session.currentFrame?.lightEstimate
    )
  }

  /// Initial setup gestures for ar scene
  private func setupGestures() {
    let spawnGesture = UITapGestureRecognizer(target: self, action: #selector(placePet(gesture:)))
    spawnGesture.numberOfTapsRequired = 1
    sceneView.addGestureRecognizer(spawnGesture)
  }

  /// Initial setup of modals
  private func setupModals() {
    // Setup modals
    if let storyboard = self.storyboard {
      // Setting pet menu modal
      if let petMenuController = storyboard
        .instantiateViewController(withIdentifier: "PetMenuModal") as? PetMenuController {
        petMenuController.petPresenter = petPresenter
        petMenuModal = ModalWindow(root: self, child: petMenuController)
      }

      // Setting dead menu modal
      if let deadMenuController = storyboard
        .instantiateViewController(withIdentifier: "PetDeadModal") as? PetDeadController {
        deadMenuController.petPresenter = petPresenter
        deadMenuModal = ModalWindow(root: self, child: deadMenuController, isShowClose: false)
      }

      // Setting phone move modal
      if let phoneMoveController = storyboard
        .instantiateViewController(withIdentifier: "PhoneMoveModal") as? PhoneMoveController {
        phoneMoveModal = ModalWindow(root: self, child: phoneMoveController, isShowClose: false)
      }

      // Setting level up modal
      if let levelUpController = storyboard
        .instantiateViewController(withIdentifier: "LevelUpModal") as? LevelUpController {
        // Set closure for close modal
        levelUpController.closeHandler = { [weak self] in
          guard let levelUpModal = self?.levelUpModal else { return }

          levelUpModal.isShow = false
        }
        levelUpModal = ModalWindow(root: self, child: levelUpController, isShowClose: false)
      }

      // Setting information modal
      let informationController = storyboard
        .instantiateViewController(withIdentifier: "InformModal")
      informModal = ModalWindow(root: self, child: informationController)

      // Setting inform peer modal
      if let informPeerController = storyboard
        .instantiateViewController(withIdentifier: "InformPeerModal") as? InformPeerController {
        informPeerController.actionHandler = { [weak self] in
          guard let activePet = self?.petPresenter.activePet else { return }

          self?.multipeerSession.shareSession(pet: activePet)
        }
        informPeerModal = ModalWindow(root: self, child: informPeerController)
      }

      // Setting active peer modal
      if let peerController = storyboard
        .instantiateViewController(withIdentifier: "PeerModal") as? PeerController {
        peerController.actionHandler = { [weak self] in
          self?.multipeerSession.stopSession()
        }
        peerModal = ModalWindow(root: self, child: peerController, isShowClose: false)
      }
    }
  }

  /// Place pet entity on ar scene
  @objc private func placePet(gesture: UITapGestureRecognizer) {
    guard let arSceneView = gesture.view as? ARSCNView else { return }

    let location = gesture.location(in: arSceneView)
    let hitTestResult = arSceneView.hitTest(location, types: .existingPlaneUsingExtent)

    guard let hitResult = hitTestResult.first else { return }

    // Get touch plane position
    let position = SCNVector3(hitResult.worldTransform.columns.3.x,
                              hitResult.worldTransform.columns.3.y,
                              hitResult.worldTransform.columns.3.z)

    // Place pet model on scene
    petPresenter.placePet(atPoint: position, on: arSceneView.scene)

    // Reset AR session
    resetSession()
  }

  /// Update lightings for scene
  // TODO: No active
  @objc func updateLighting() {
    // Check how many minutes left from last update lightings

    // Update lightings
    DispatchQueue.main.async { [weak self] in
      if let lightEstimate = self?.sceneView.session.currentFrame?.lightEstimate {
        guard let strongSelf = self else { return }
        let ambientIntensity = lightEstimate.ambientIntensity
        let ambientColorTemperature = lightEstimate.ambientColorTemperature
        let differenceIntensity = strongSelf.lastIntensityLightings - ambientIntensity

        // If ambient lightings is changed
        guard differenceIntensity < -400 || differenceIntensity > 400 else { return }

        // Update color
        strongSelf.petPresenter.updateLightings(intensity: ambientIntensity, temperature: ambientColorTemperature)
        strongSelf.lastIntensityLightings = ambientIntensity
        Logger.info("Update lightings - \(strongSelf.lastIntensityLightings), \(ambientIntensity)", from: strongSelf)
      }
    }
  }

  /// Show inform game modal
  private func showInformModal() {
    guard let informModal = self.informModal else { return }

    informModal.isShow = true
  }

  /// Show pet dead modal
  private func showDeadMenuModal() {
    guard let deadMenuModal = self.deadMenuModal else { return }

    deadMenuModal.isShow = true
  }

  // Show phone move modal
  private func showPhoneMoveModal() {
    // Block open this modal if pet is dead
    if let deadMenuModal = self.deadMenuModal, deadMenuModal.isShow {
      return
    }

    if let phoneMoveModal = self.phoneMoveModal {
      // Do not open if is already opened
      guard !phoneMoveModal.isShow else { return }

      phoneMoveModal.isShow = true

      DispatchQueue.syncTimeoutRun(timeout: 5) {
        phoneMoveModal.isShow = false
      }
    }
  }

  /// Show level up modal
  private func showLevelUpModal() {
    guard let levelUpModal = self.levelUpModal else { return }

    if let deadMenuModal = self.deadMenuModal {
      guard !deadMenuModal.isShow else { return }
    }

    levelUpModal.isShow = true
  }

  /// Show inform peet modal
  private func showInformPeerModal() {
    guard let informPeerModal = self.informPeerModal else { return }

    informPeerModal.isShow = true

    // Start searching peer
    multipeerSession.startSearchPeer()
  }

  /// Show inform peet modal
  private func showPeerModal() {
    guard let informPeerModal = self.informPeerModal,
      let peerModal = self.peerModal else { return }

    informPeerModal.isShow = false
    peerModal.isShow = true
  }
}

// MARK: PetPresenterDelegate

extension PetController: PetPresenterDelegate {
  /// Update UI progress indicators
  func updatedProgress(value: Float, type: PetStateUpdateTypes) {
    switch type {
    case .eat:
      progressEat.updateProgress(value)
    case .tired:
      progressTired.updateProgress(value)
    case .happy:
      progressHappy.updateProgress(value)
    case .cleanness:
      progressCleanness.updateProgress(value)
    case .dead:
      showDeadMenuModal()
    case .level:
      showLevelUpModal()
    case .point:
      let points = Int(value)
      labelPoints.text = "\(points)"
    default:
      break
    }
  }

  /// Update visible active state of menu
  func updatedActiveEventState(isActive: Bool) {
    if isActive {
      UIView.animate(withDuration: 0.3, animations: {
        self.menuScroll.alpha = 0.2
      })
    } else {
      UIView.animate(withDuration: 0.3, animations: {
        self.menuScroll.alpha = 1
      })
    }
  }

  /// Update visibility controls menu elements
  func updatePlacePetStatus(isPlaced: Bool) {
    labelPlaceHelp.isHidden = isPlaced
    menuScroll.isHidden = !isPlaced

    // Hide all "Place Zone" planes
    for placeZone in placeZones {
      placeZone.isHidden = isPlaced
    }
  }
}

// MARK: - MultipeerSessionDelegate

extension PetController: MultipeerSessionDelegate {
  func updateSessionStatus(_: MultipeerSession, isStarted: Bool) {
    guard let peerModal = self.peerModal else { return }

    if isStarted {
      // Hide inform peer modal and show peer modal
      showPeerModal()
    } else {
      // Close peer modal
      peerModal.isShow = false
    }

    // Hide or show models on scene
    petPresenter.visibleModels(!isStarted)
  }

  func updateConnectedPeer(_: MultipeerSession, isConnected: Bool) {
    // Change button start visit status
    if let informPeerController = self.informPeerModal?.childController as? InformPeerController {
      informPeerController.buttonStartVisit.isAccess = isConnected
    }

    // Stop active session
    if let peerModal = self.peerModal, peerModal.isShow, !isConnected {
      multipeerSession.stopSession()
    }
  }

  func receivedFriendPet(_: MultipeerSession, peerModel: PeerModel) {
    petPresenter.placeFriendPet(peerModel: peerModel)
  }
}

// MARK: - ARSCNViewDelegate, ARSessionDelegate

extension PetController: ARSCNViewDelegate, ARSessionDelegate {
  func session(_: ARSession, didUpdate frame: ARFrame) {
    // Rotate pet to camera
    petPresenter.startPetRotate(to: frame.camera)
  }

  /// Add "place zone" indicator
  func renderer(_: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
    let placeZone = PlaceZoneModel(anchor: planeAnchor)

    DispatchQueue.main.async { [weak self] in
      placeZone.isHidden = self?.petPresenter.isPetPlaced ?? false
      node.addChildNode(placeZone)
    }

    placeZones.append(placeZone)
  }

  /// Update size and position at "place zone" indicator
  func renderer(_: SCNSceneRenderer, didUpdate _: SCNNode, for anchor: ARAnchor) {
    let filterPlaceZone = placeZones.filter { zone in
      zone.anchor.identifier == anchor.identifier
    }.first

    guard let placeZone = filterPlaceZone else { return }

    DispatchQueue.main.async { [weak self] in
      placeZone.isHidden = self?.petPresenter.isPetPlaced ?? false

      if let arAnchor = anchor as? ARPlaneAnchor {
        placeZone.update(anchor: arAnchor)
      }
    }
  }
}

// MARK: UIMenuScrollViewDelegate

extension PetController: UIMenuScrollViewDelegate {
  func menuScroll(menuScroll _: UIMenuScrollView) -> UIImage? {
    return UIImage(named: "menu-scroll-center")
  }

  func menuScroll(menuScroll _: UIMenuScrollView) -> Int {
    return MenuActionTypes.allCases.count
  }

  func menuScroll(menuScroll _: UIMenuScrollView, createdButton: UIButton, index: Int) {
    let menuItem = MenuActionTypes.allCases[index]
    let buttonImage = UIImage(named: menuItem.rawValue)

    createdButton.setImage(buttonImage, for: .normal)
  }

  func menuScroll(menuScroll _: UIMenuScrollView, touchSender _: UIButton, index: Int) {
    let menuItem = MenuActionTypes.allCases[index]

    petPresenter.startMenuAction(type: menuItem)
  }
}
