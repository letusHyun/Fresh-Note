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
    requestEntity: UNNotificationRequestEntity
  ) -> AnyPublisher<Void, any Error> {
    return Future { promise in
      let content = UNMutableNotificationContent()
      content.title = requestEntity.title
      content.body = requestEntity.body
      content.sound = .default
      
      let components = Calendar.current.dateComponents(
        [.year, .month, .day, .hour, .minute],
        from: requestEntity.date
      )
      let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
      
      let request = UNNotificationRequest(
        identifier: requestEntity.noficationID,
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
  
  func checkRegisteredNotifications() -> AnyPublisher<Bool, any Error> {
    return Future { [weak self] promise in
      self?.notificationCenter.getPendingNotificationRequests { requests in
        let ifRegistered = !requests.isEmpty
        return promise(.success(ifRegistered))
      }
    }
    .eraseToAnyPublisher()
  }
}
