//
//  AppDelegate.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 08/10/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import CoreData
import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "Ploot")
    container.loadPersistentStores(completionHandler: { _, error in
      if let error = error {
        fatalError("Unresolved error, \((error as NSError).userInfo)")
      }
    })
    return container
  }()

  func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    return true
  }

  func applicationWillResignActive(_: UIApplication) {
    //
  }

  func applicationDidEnterBackground(_: UIApplication) {
    //
  }

  func applicationWillEnterForeground(_: UIApplication) {
    //
  }

  func applicationDidBecomeActive(_: UIApplication) {
    //
  }

  func applicationWillTerminate(_: UIApplication) {
    //
  }
}
