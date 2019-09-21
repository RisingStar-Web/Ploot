//
//  StorePresenter.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 26/10/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import Foundation

protocol StorePresenterDelegate {
  /// The call if pet have be selected
  func petSelected(storePet: StoreModel)
}

class StorePresenter {
  /// Selected pet
  private var selectedPet: StoreModel?

  /// Manager for loading data
  private lazy var coreDataManager = CoreDataManager.data

  /// Callback UI delegate
  public var delegate: StorePresenterDelegate?

  /// Select pet in pet store
  public func selectPet(index: Int) {
    guard let delegate = self.delegate else { return }
    let storePet = GlobalData.data.petsListInStore[index]

    // Deselect last selected pet
    if let selectedPet = self.selectedPet {
      selectedPet.isSelected = false
    }

    storePet.isSelected = true
    selectedPet = storePet
    delegate.petSelected(storePet: storePet)
  }

  /// Save selected pet
  public func applySelectedPet() {
    guard let delegate = self.delegate,
      let selectedPet = self.selectedPet else { return }

    if let petModel = PetModel(name: selectedPet.name) {
      // Sets creating date of pet and start points
      petModel.createDate = Date()
      petModel.lastPointsUpdate = Date()
      petModel.points = GlobalData.data.countPointsOneDay

      selectedPet.isSelected = false
      delegate.petSelected(storePet: selectedPet)
      coreDataManager.savePetData(petModel: petModel)
    }
  }
}
