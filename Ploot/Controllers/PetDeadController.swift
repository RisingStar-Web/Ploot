//
//  PetDeadController.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 30/11/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import UIKit

class PetDeadController: UIViewController {
  /// Pet presenter, set from Pet Controller
  public var petPresenter: PetPresenter?

  /// Core data manager
  private(set) lazy var coreDataManager = CoreDataManager.data

  /// Reset pet in core data
  @IBAction func resetPet(sender _: UIButton) {
    petPresenter?.clearPet()
    coreDataManager.clearData()
    performSegue(withIdentifier: "Store", sender: self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
  }
}
