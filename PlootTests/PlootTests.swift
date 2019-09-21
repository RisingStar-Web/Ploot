//
//  PlootTests.swift
//  PlootTests
//
//  Created by Aleksey Pleshkov on 24/10/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import UserNotifications
import XCTest
@testable import Ploot

class PlootTests: XCTestCase {
  var petController: PetController?
  var petPresenter: PetPresenter?

  override func setUp() {
    petController = PetController()

    if let petController = self.petController {
      petPresenter = petController.petPresenter
    }
  }

  func testInit() {
    XCTAssertNotNil(petController, "PetController is nil")
    XCTAssertNotNil(petPresenter, "PetPresenter is nil")
  }

  func testPet() {
    guard let petPresenter = self.petPresenter else { return }

    // Check loading pet
    petPresenter.loadingPet()
    XCTAssertNotNil(petPresenter.activePet, "ActivePet is nil")

    guard let activePet = petPresenter.activePet else { return }

    // Check loading animations
    XCTAssert(!activePet.animations.isEmpty, "Not loading pet animations")
  }

  func testPetMenuAction() {
    guard let petPresenter = self.petPresenter,
      let activePet = petPresenter.activePet else { return }

    // Check work start action
    let petEat = activePet.eat
    let petTired = activePet.tired
    let petPoints = activePet.points

    // Test eat and points
    petPresenter.startMenuAction(type: .eat)
    XCTAssert(activePet.eat != petEat, "StartMenuAction not working eat")
    XCTAssert(activePet.points != petPoints, "Points not remove if pet is eating")

    // Test sleep
    petPresenter.isActiveEvent = false
    petPresenter.startMenuAction(type: .sleep)
    XCTAssert(activePet.isSleep, "StartMenuAction not working change pet state to sleep")

    // Test tired
    petPresenter.isActiveEvent = false
    petPresenter.startMenuAction(type: .play)
    XCTAssert(activePet.tired != petTired, "StartMenuAction not working tired")
  }

  func testGlobalFunctionality() {
    // Test date from birth
    guard let dateStartDays = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else {
      XCTAssert(false, "Error get date from minus 7 days")
      return
    }
    let daysLeftFromDate = GlobalData.data.dateToLeft(date: dateStartDays, type: .day)
    XCTAssert(daysLeftFromDate == 7, "Days to left not work")

    // Minutes to left params
    let minutesLeftFromParams = GlobalData.data.minutesToEndParams(param: 1)
    XCTAssert(minutesLeftFromParams == 960, "Minutes to end params")

    // Days to next level
    guard let dateStartNewLevel = Calendar.current.date(byAdding: .day, value: -3, to: Date()) else {
      XCTAssert(false, "Error get date from minus 3 days")
      return
    }
    let daysNextLevel = GlobalData.data.isNewLevel(createDate: dateStartNewLevel, level: 1)
    XCTAssert(daysNextLevel, "Not add new level to pet")

    let daysNextLevelTwo = GlobalData.data.isNewLevel(createDate: dateStartNewLevel, level: 2)
    XCTAssertFalse(daysNextLevelTwo, "Add level to new pet")
  }

  func testNotifications() {
    guard let petPresenter = self.petPresenter else { return }
    let current = UNUserNotificationCenter.current()

    // Change states of active pet for create notification
    petPresenter.backgroundPetStateUpdate()

    // Check exist notifications
    current.getPendingNotificationRequests { requests in
      guard let notification = requests.first else {
        XCTFail("Not found notifications")
        return
      }

      XCTAssert(notification.identifier == "global", "Not found notification with 'global' identifier")
    }
  }

  func testPetController() {
    guard let petController = self.petController,
      let activePet = self.petPresenter?.activePet else { return }

    activePet.level += 1
    XCTAssert(petController.levelUpModal?.isShow == true, "LevelUpModal not show")

    activePet.eat = 0
    XCTAssert(petController.deadMenuModal?.isShow == true, "PetDeadModal not show")
  }

  func buyDecorations() {
    guard let petPresenter = self.petPresenter,
      let activePet = petPresenter.activePet else { return }

    let decorationsList = GlobalData.data.productsListInPetMenu

    activePet.points = 1000

    for (index, decoration) in decorationsList.enumerated() {
      petPresenter.placeDecoration(index: index)

      XCTAssert(activePet.decorationsList.contains(decoration.name), "No exist \(decoration.name) decoration in docorations list")
    }
  }
}
