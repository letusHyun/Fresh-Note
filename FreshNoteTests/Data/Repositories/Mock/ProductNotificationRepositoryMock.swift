//
//  ProductNotificationRepositoryMock.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import Combine
import Foundation

final class ProductNotificationRepositoryMock: ProductNotificationRepository {
  private(set) var saveProuctNotificationCallCount = 0
  private(set) var fetchProductNotificationsCallCount = 0
  
  var saveProuctNotificationResult: AnyPublisher<Void, any Error>!
  var fetchProductNotificationsResult: AnyPublisher<[ProductNotification], any Error>!
  
  func saveProuctNotification(productNotification: ProductNotification) -> AnyPublisher<Void, any Error> {
    self.saveProuctNotificationCallCount += 1
    return self.saveProuctNotificationResult
  }
  
  func fetchProductNotifications() -> AnyPublisher<[ProductNotification], any Error> {
    self.fetchProductNotificationsCallCount += 1
    return self.fetchProductNotificationsResult
  }
}