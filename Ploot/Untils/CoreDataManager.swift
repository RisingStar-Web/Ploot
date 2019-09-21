//
//  CoreData.swift
//  BrainCalc
//
//  Created by Aleksey Pleshkov on 26.06.2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import CoreData
import UIKit

class CoreDataManager {
  /// Managed object context
  private var context: NSManagedObjectContext?

  /// Creates core data manager
  public static var data = CoreDataManager()

  /// Init
  private init() {
    if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
      let context = appDelegate.persistentContainer.viewContext
      self.context = context
    }
  }

  // MARK: - Pet data

  /// Get pet data if exist
  public var petModelFromData: PetModel? {
    do {
      let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Main")
      guard let context = self.context else { throw CoreDataManagerError.noContext }
      guard let selectObjects = try context.fetch(request) as? [NSManagedObject] else { return nil }
      guard let data = selectObjects.last else { throw CoreDataManagerError.noResult }

      guard
        // Main data
        let level = data.value(forKey: "level") as? Int,
        let name = data.value(forKey: "name") as? String,
        let eat = data.value(forKey: "eat") as? Float,
        let tired = data.value(forKey: "tired") as? Float,
        let happy = data.value(forKey: "happy") as? Float,
        let point = data.value(forKey: "points") as? Int,
        let decorations = data.value(forKey: "decorations") as? String,
        let cleanness = data.value(forKey: "cleanness") as? Float,
        let isSleep = data.value(forKey: "isSleep") as? Bool,
        // Dates
        let createDate = data.value(forKey: "createDate") as? Date,
        let lastPointsUpdate = data.value(forKey: "lastPointsUpdate") as? Date,
        let lastUpdate = data.value(forKey: "lastUpdate") as? Date else {
        throw CoreDataManagerError.noKey
      }

      let minutesLeftParamsUpdate = GlobalData.data.dateToLeft(date: lastUpdate, type: .minute)
      let minutesLeftPointsUpdate = GlobalData.data.dateToLeft(date: lastPointsUpdate, type: .minute)
      let countStateChange = GlobalData.data.countRemovePetState * Float(minutesLeftParamsUpdate)

      // Logger
      Logger.info("Loading pet after \(minutesLeftParamsUpdate) minutes", from: self)
      Logger.info("Count state change \(countStateChange)", from: self)

      if let petModel = PetModel(name: name, level: level) {
        petModel.eat = eat - countStateChange
        petModel.happy = happy - countStateChange
        petModel.points = point
        petModel.decorationsList = decorations.components(separatedBy: ",")
        petModel.cleanness = cleanness - countStateChange
        petModel.daysFromBirth = GlobalData.data.dateToLeft(date: createDate, type: .day)
        petModel.lastUpdate = lastUpdate
        petModel.createDate = createDate
        petModel.lastPointsUpdate = lastPointsUpdate

        // Add points to pet if app run after 24 hours
        if minutesLeftPointsUpdate >= 1440 {
          petModel.points += GlobalData.data.countPointsOneDay
          petModel.lastPointsUpdate = Date()
        }

        // Add/remove tired if pet sleeping or not
        petModel.tired = isSleep ? tired + countStateChange : tired - countStateChange

        // If tired full - wake up pet
        petModel.isSleep = tired >= 1 ? false : isSleep

        // Set is dead
        petModel.isDead = eat <= 0 || tired <= 0 || happy <= 0

        return petModel
      }
    } catch let e {
      Logger.error("Error get pet from core data - \(e)", from: self)
    }

    return nil
  }

  /// Save pet data from pet model
  public func savePetData(petModel: PetModel) {
    do {
      guard let context = self.context else { throw CoreDataManagerError.noContext }
      guard let entity = NSEntityDescription.entity(forEntityName: "Main", in: context) else {
        throw CoreDataManagerError.noMainEntity
      }
      let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Main")
      guard let selectObjects = try context.fetch(request) as? [NSManagedObject] else { return }
      let main = selectObjects.last ?? NSManagedObject(entity: entity, insertInto: context)
      // Create array decorations list by name of decoration
      let decorations = petModel.decorationsList.joined(separator: ",")

      petModel.lastUpdate = Date()

      main.setValue(petModel.level, forKey: "level")
      main.setValue(petModel.name, forKey: "name")
      main.setValue(petModel.eat, forKey: "eat")
      main.setValue(petModel.tired, forKey: "tired")
      main.setValue(petModel.happy, forKey: "happy")
      main.setValue(petModel.points, forKey: "points")
      main.setValue(decorations, forKey: "decorations")
      main.setValue(petModel.cleanness, forKey: "cleanness")
      main.setValue(petModel.isSleep, forKey: "isSleep")
      main.setValue(petModel.lastUpdate, forKey: "lastUpdate")
      main.setValue(petModel.lastPointsUpdate, forKey: "lastPointsUpdate")
      main.setValue(petModel.createDate, forKey: "createDate")

      try context.save()

      Logger.info("Save pet at \(String(describing: petModel.lastUpdate))", from: self)
    } catch let e {
      Logger.error("Error save pet to core data - \(e)", from: self)
    }
  }

  /// Delete pet data from Core data
  public func clearData() {
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Main")

    do {
      guard let context = self.context else { throw CoreDataManagerError.noContext }
      guard let selectObjects = try context.fetch(request) as? [NSManagedObject] else { return }

      for object in selectObjects {
        context.delete(object)
      }

      try context.save()
    } catch let e {
      Logger.error("Error save pet to core data - \(e)", from: self)
    }
  }
}
