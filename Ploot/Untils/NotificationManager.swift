//
//  NotificationManager.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 24/10/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import Foundation
import UserNotifications

class NotificationManager {
  /// Not access to create new class
  private init() {}

  /// Creates notification class
  public static var data = NotificationManager()

  /// Send push notification for end eat
  public func pushAttensionMe(params: [Float]) {
    let sortedParams = params.sorted { a, b in
      b > a
    }.first

    guard let param = sortedParams else { return }

    let desc = NSLocalizedString("I miss you! Please come back!", comment: "Notification param")
    let uid = "global"
    let minutesToEndParmas = GlobalData.data.minutesToEndParams(param: param)
    let timeout = minutesToEndParmas > 20 ? minutesToEndParmas - 10 : minutesToEndParmas
    let seconds = TimeInterval(timeout * 60)

    pushNotification(desc: desc, uid: uid, seconds: seconds)

    // Logger
    Logger.info("Send notification after \(timeout) minutes (\(param) in \(params))", from: self)
  }

  /// Push notifications after N seconds
  public func pushNotification(desc: String, uid: String, seconds: TimeInterval) {
    removeNotification(withUids: [uid])

    let date = Date(timeIntervalSinceNow: seconds)
    let content = UNMutableNotificationContent()

    // Notification content
    content.title = NSLocalizedString("Hey!", comment: "Notification title")
    content.body = desc
    content.sound = UNNotificationSound.default

    // Set data to notification
    let calendar = Calendar(identifier: .gregorian)
    let components = calendar.dateComponents([.month, .day, .hour, .minute, .second], from: date)
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    let requiest = UNNotificationRequest(identifier: uid, content: content, trigger: trigger)
    let center = UNUserNotificationCenter.current()

    center.add(requiest, withCompletionHandler: nil)
  }

  /// Remove notifications by uids
  private func removeNotification(withUids uids: [String]) {
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: uids)
  }
}
