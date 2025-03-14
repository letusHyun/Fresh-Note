//
//  SavePushNotificationUseCaseMock.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import Combine
import Foundation

final class SavePushNotificationUseCaseMock: SavePushNotificationUseCase {
  private(set) var saveNotificationCallCount = 0
  private(set) var lastSavedProduct: Product?
  
  var saveNotificationResult: AnyPublisher<Void, any Error>!
  
  func resetCallCounts() {
    self.saveNotificationCallCount = 0
    self.lastSavedProduct = nil
  }
  
  func saveNotification(product: Product) -> AnyPublisher<Void, any Error> {
    self.saveNotificationCallCount += 1
    self.lastSavedProduct = product
    return self.saveNotificationResult
  }
} 