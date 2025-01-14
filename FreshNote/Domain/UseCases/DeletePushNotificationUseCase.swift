//
//  DeletePushNotificationUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 1/14/25.
//

import Foundation

protocol DeletePushNotificationUseCase {
  func deleteNotification(productID: DocumentID)
  func deleteAllNotifications(productIDs: [DocumentID])
}

final class DefaultDeletePushNotificationUseCase: DeletePushNotificationUseCase {
  private let pushNotificationRepository: any PushNotificationRepository
  
  init(
    pushNotificationRepository: any PushNotificationRepository
  ) {
    self.pushNotificationRepository = pushNotificationRepository
  }
  
  func deleteNotification(productID: DocumentID) {
    self.pushNotificationRepository.deleteNotificaion(notificationIDs: [productID])
  }
  
  func deleteAllNotifications(productIDs: [DocumentID]) {
    self.pushNotificationRepository.deleteNotificaion(notificationIDs: productIDs)
  }
}
