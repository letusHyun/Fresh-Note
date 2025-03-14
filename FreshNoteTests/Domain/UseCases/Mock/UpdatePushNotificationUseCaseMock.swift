//
//  UpdatePushNotificationUseCaseMock.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import Combine
import Foundation

final class UpdatePushNotificationUseCaseMock: UpdatePushNotificationUseCase {
  private(set) var updateNotificationCallCount = 0
  private(set) var updateNotificationsCallCount = 0
  private(set) var lastUpdatedProduct: Product?
  
  var updateNotificationResult: AnyPublisher<Void, any Error>!
  var updateNotificationsResult: AnyPublisher<Void, any Error>!
  
  func resetCallCounts() {
    self.updateNotificationCallCount = 0
    self.updateNotificationsCallCount = 0
    self.lastUpdatedProduct = nil
  }
  
  func updateNotification(product: Product) -> AnyPublisher<Void, any Error> {
    self.updateNotificationCallCount += 1
    self.lastUpdatedProduct = product
    return self.updateNotificationResult
  }
  
  func updateNotifications() -> AnyPublisher<Void, any Error> {
    self.updateNotificationsCallCount += 1
    return self.updateNotificationsResult
  }
} 
