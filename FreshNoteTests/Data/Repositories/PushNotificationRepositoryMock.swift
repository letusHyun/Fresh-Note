//
//  PushNotificationRepositoryMock.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import Combine
import Foundation

final class PushNotificationRepositoryMock: PushNotificationRepository {
  private(set) var scheduleNotificationCallCount = 0
  private(set) var deleteNotificaionCallCount = 0
  private(set) var deletedNotificationIDs: [DocumentID]?
  private(set) var lastRequestEntity: UNNotificationRequestEntity?
  
  var scheduleNotificationResult: AnyPublisher<Void, any Error>!
  
  func scheduleNotification(
    requestEntity: UNNotificationRequestEntity
  ) -> AnyPublisher<Void, any Error> {
    self.scheduleNotificationCallCount += 1
    self.lastRequestEntity = requestEntity
    return self.scheduleNotificationResult
  }
  
  func deleteNotificaion(notificationIDs: [DocumentID]) {
    self.deleteNotificaionCallCount += 1
    self.deletedNotificationIDs = notificationIDs
  }
} 
