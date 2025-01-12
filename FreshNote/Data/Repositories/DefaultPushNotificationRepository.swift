//
//  DefaultPushNotificationRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 1/13/25.
//

import Combine
import Foundation
import UserNotifications

final class DefaultPushNotificationRepository: PushNotificationRepository {
  private let notificationCenter: UNUserNotificationCenter
  
  init(notificationCenter: UNUserNotificationCenter = .current()) {
    self.notificationCenter = notificationCenter
  }
  
  func scheduleNotification(
    noficationID: DocumentID,
    title: String,
    body: String,
    date: Date
  ) -> AnyPublisher<Void, any Error> {
    return Future { promise in
      let content = UNMutableNotificationContent()
      content.title = title
      content.body = body
      content.sound = .default
      
      let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
      let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
      
      let request = UNNotificationRequest(
        identifier: noficationID.didString,
        content: content,
        trigger: trigger
      )
      
      self.notificationCenter.add(request) { error in
        if let error = error {
          promise(.failure(error))
          return
        }
        promise(.success(()))
      }
    }
    .eraseToAnyPublisher()
  }
}
