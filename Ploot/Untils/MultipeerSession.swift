//
//  MultipeerSession.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 04/02/2019.
//  Copyright © 2019 Aleksey Pleshkov. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol MultipeerSessionDelegate {
  /// Update status of running or stopped session
  func updateSessionStatus(_ multipeer: MultipeerSession, isStarted: Bool)

  /// Update status of connected peer
  func updateConnectedPeer(_ multipeer: MultipeerSession, isConnected: Bool)

  /// Received friend pet
  func receivedFriendPet(_ multipeer: MultipeerSession, peerModel: PeerModel)
}

/// Multipeer session manager
class MultipeerSession: NSObject {
  static let serviceType = "ploot-ar-multi"

  private let myPeerID: MCPeerID
  private let session: MCSession
  private let serviceAdvertiser: MCNearbyServiceAdvertiser
  private let serviceBrowser: MCNearbyServiceBrowser
  private var isStartSearch = false

  var delegate: MultipeerSessionDelegate?

  /// Get connected peer id
  private var connectedPeerID: MCPeerID? {
    didSet {
      if let delegate = self.delegate {
        delegate.updateConnectedPeer(self, isConnected: isConnectedPeer)
      }
    }
  }

  /// Status of running session
  private(set) var isRunningSession: Bool = false {
    didSet {
      if let delegate = self.delegate {
        delegate.updateSessionStatus(self, isStarted: isRunningSession)
      }
    }
  }

  /// If peer is exist and connected
  var isConnectedPeer: Bool {
    return self.connectedPeerID != nil
  }

  override init() {
    myPeerID = MCPeerID(displayName: UIDevice.current.name)
    session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
    serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: MultipeerSession.serviceType)
    serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: MultipeerSession.serviceType)

    super.init()

    session.delegate = self
    serviceAdvertiser.delegate = self
    serviceBrowser.delegate = self
  }

  func startSearchPeer() {
    guard !isStartSearch else { return }

    serviceAdvertiser.startAdvertisingPeer()
    serviceBrowser.startBrowsingForPeers()
    stopSearchPeerTimeout()
    isStartSearch = true

    Logger.info("Start multipeer search session", from: self)
  }

  func stopSearchPeer() {
    serviceAdvertiser.stopAdvertisingPeer()
    serviceBrowser.stopBrowsingForPeers()
    isStartSearch = false
    connectedPeerID = nil
  }

  /// Stop search session after timeout
  func stopSearchPeerTimeout() {
    DispatchQueue.global().async { [weak self] in
      sleep(10)

      guard let multipeer = self else { return }

      if !multipeer.isConnectedPeer, !multipeer.isRunningSession {
        multipeer.stopSearchPeer()
        Logger.info("Stop multipeer session", from: multipeer)
        return
      }

      multipeer.stopSearchPeerTimeout()
    }
  }

  /// Share session to peers
  func shareSession(pet: PetModel) {
    // Creates peer model with params for send to peers
    let params: [String: Any] = [
      "name": pet.name,
      "level": pet.level,
    ]

    sendParamsToPeers(params)
    isRunningSession = true
  }

  /// Stop session and send about it to peer device
  func stopSession() {
    let params: [String: Any] = ["isEnd": true]

    sendParamsToPeers(params)
    isRunningSession = false
  }

  /// Send data to peers users
  private func sendParamsToPeers(_ params: [String: Any]) {
    guard isConnectedPeer else {
      Logger.error("Peers not found", from: self)
      return
    }

    let peerModel = PeerModel(params: params)

    // Archived peer model to data
    guard let data = try? NSKeyedArchiver.archivedData(withRootObject: peerModel, requiringSecureCoding: true) else {
      Logger.error("Can't encode map", from: self)
      return
    }

    do {
      try session.send(data, toPeers: session.connectedPeers, with: .reliable)
    } catch {
      Logger.error("Error send data to peers - \(error.localizedDescription)", from: self)
    }
  }

  /// Get data from seed
  private func receivePeerData(_ data: Data, from peer: MCPeerID) {
    do {
      // Unarchived peer model data
      if let peerModel = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? PeerModel {
        // Save who provided the map
        connectedPeerID = peer

        if let delegate = self.delegate {
          delegate.receivedFriendPet(self, peerModel: peerModel)
        }
      }
    } catch {
      Logger.error("Can't decode data received from \(peer) - \(error.localizedDescription)", from: self)
    }
  }
}

// MARK: - MCSessionDelegate

extension MultipeerSession: MCSessionDelegate {
  func session(_: MCSession, peer _: MCPeerID, didChange _: MCSessionState) {}

  func session(_: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    receivePeerData(data, from: peerID)
  }

  func session(_: MCSession, didReceive _: InputStream, withName _: String, fromPeer _: MCPeerID) {
    Logger.error("This service does not send/receive streams.", from: self)
  }

  func session(_: MCSession, didStartReceivingResourceWithName _: String, fromPeer _: MCPeerID, with _: Progress) {
    Logger.error("This service does not send/receive streams.", from: self)
  }

  func session(_: MCSession, didFinishReceivingResourceWithName _: String, fromPeer _: MCPeerID, at _: URL?, withError _: Error?) {
    Logger.error("This service does not send/receive streams.", from: self)
  }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MultipeerSession: MCNearbyServiceAdvertiserDelegate {
  func advertiser(_: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer _: MCPeerID, withContext _: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
    invitationHandler(true, session)
  }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension MultipeerSession: MCNearbyServiceBrowserDelegate {
  func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo _: [String: String]?) {
    guard !isConnectedPeer else { return }

    connectedPeerID = peerID
    browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)

    Logger.info("Found peer - \(peerID.displayName)", from: self)
  }

  func browser(_: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
    connectedPeerID = nil

    Logger.info("Lost peer - \(peerID.displayName)", from: self)
  }
}
