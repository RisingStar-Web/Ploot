//
//  GlobalData.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 25/10/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import Foundation

class GlobalData {
  /// Not access to create new class
  private init() {}

  /// Creates global data class
  public static var data = GlobalData()

  /// How much remove value from pet state in one minutes
  public var countRemovePetState: Float {
    return Float(1 / Float(hoursToRemovePetState) / 60)
  }

  /// How much add value to pet state in one timeout
  public var countAddPetState: Float {
    return countRemovePetState * 80
  }

  /// How much remove value from pet state in one background timeout if app run
  public var countRemovePetStateBackground: Float {
    return countRemovePetState
  }

  /// The number of hours to change pet indicators from 1 to 0
  public let hoursToRemovePetState = 16

  /// Timeout in seconds for remove pet states values in run app
  public let timeoutRemovePetState = 10

  /// Timeout in seconds for add bonus if pet is go visit
  public let timeoutPeerAddBonus = 60

  /// Block timeout for start new pet event
  public let timeoutToNextPetEvent = 5

  /// Add bonus points for open application on day
  public let countPointsOneDay: Int = 100

  /// Add bonus points if pet is level up
  public let countPointsLevelUp: Int = 30

  /// How much left days to new level
  public let daysToNewLevel: Int = 3

  /// Max level for pet
  public let maxPetLevel: Int = 10

  /// Catalog list of pets for store
  private var _petsListInStore: [StoreModel]?
  public var petsListInStore: [StoreModel] {
    guard let list = self._petsListInStore else {
      let raccoon = NSLocalizedString("Raccoon", comment: "Pet visible name")
      let bear = NSLocalizedString("Bear", comment: "Pet visible name")
      let fox = NSLocalizedString("Fox", comment: "Pet visible name")
      let panda = NSLocalizedString("Red Panda", comment: "Pet visible name")
      let wolf = NSLocalizedString("Wolf", comment: "Pet visible name")

      let newList: [StoreModel] = [
        StoreModel(name: "raccoon", visibleName: raccoon),
        StoreModel(name: "bear", visibleName: bear),
        StoreModel(name: "fox", visibleName: fox),
        StoreModel(name: "panda", visibleName: panda),
        StoreModel(name: "wolf", visibleName: wolf),
      ]

      _petsListInStore = newList

      return newList
    }

    return list
  }

  /// Catalog products of pet decorations
  public var productsListInPetMenu: [ProductModel] {
    let flower = NSLocalizedString("Flower", comment: "Decorations visible name")
    let chair = NSLocalizedString("Chair", comment: "Decorations visible name")
    let fence = NSLocalizedString("Fence", comment: "Decorations visible name")
    let pokeball = NSLocalizedString("Pokeball", comment: "Decorations visible name")

    return [
      ProductModel(name: "flower", visibleName: flower, price: 200),
      ProductModel(name: "chair", visibleName: chair, price: 200),
      ProductModel(name: "fence", visibleName: fence, price: 300),
      ProductModel(name: "pokeball", visibleName: pokeball, price: 120),
    ]
  }

  /// Get count minutes to left params
  public func minutesToEndParams(param: Float) -> Int {
    let result = Float(hoursToRemovePetState) * 60 * param

    return Int(result)
  }

  /// Get count minutes to left from end date
  public func dateToLeft(date dateStart: Date, type: Calendar.Component) -> Int {
    let dateEnd = Date()
    let calendar = Calendar(identifier: .gregorian)
    let component = calendar.dateComponents([type], from: dateStart, to: dateEnd)

    switch type {
    case .second:
      guard let seconds = component.second else { return 0 }

      return seconds
    case .minute:
      guard let minutes = component.minute else { return 0 }

      return minutes
    default:
      guard let days = component.day else { return 0 }

      return days
    }
  }

  /// Check add new pet level
  public func isNewLevel(createDate: Date, level: Int) -> Bool {
    if level >= maxPetLevel { return false }

    let daysLeft = dateToLeft(date: createDate, type: .day)
    let countDaysToNextLevel = daysToNewLevel * level

    return daysLeft >= countDaysToNextLevel
  }
}
