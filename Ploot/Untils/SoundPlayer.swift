//
//  SoundPlayer.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 16/12/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import AVFoundation
import Foundation

class SoundPlayer {
  private var player: AVAudioPlayer?

  private init() {}

  /// Creating sound player
  public static var player = SoundPlayer()

  /// Play sound by enum type
  public func play(type: SoundTypes) {
    guard let url = Bundle.main.url(forResource: type.rawValue, withExtension: "wav") else {
      Logger.error("Not found sound \(type.rawValue)", from: self)
      return
    }

    do {
      try AVAudioSession.sharedInstance().setActive(true, options: [])

      self.player = try AVAudioPlayer(contentsOf: url)

      guard let player = self.player else { return }

      player.play()
    } catch let e {
      Logger.error("\(e.localizedDescription)", from: self)
    }
  }
}
