//
//  DeletePushNotificationUseCaseMock.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import Foundation

final class DeletePushNotificationUseCaseMock: DeletePushNotificationUseCase {
  private(set) var deleteNotificationCallCount = 0
  private(set) var deleteAllNotificationsCallCount = 0
  
  private(set) var lastDeletedProductID: DocumentID?
  private(set) var lastDeletedProductIDs: [DocumentID]?
  
  func resetCallCounts() {
    self.deleteNotificationCallCount = 0
    self.deleteAllNotificationsCallCount = 0
    self.lastDeletedProductID = nil
    self.lastDeletedProductIDs = nil
  }
  
  func deleteNotification(productID: DocumentID) {
    self.deleteNotificationCallCount += 1
    self.lastDeletedProductID = productID
  }
  
  func deleteAllNotifications(productIDs: [DocumentID]) {
    self.deleteAllNotificationsCallCount += 1
    self.lastDeletedProductIDs = productIDs
  }
}
