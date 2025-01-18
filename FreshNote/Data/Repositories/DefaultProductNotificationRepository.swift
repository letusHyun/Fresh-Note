//
//  DefaultProductNotificationRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 1/15/25.
//

import Combine
import Foundation

final class DefaultProductNotificationRepository: ProductNotificationRepository {
  private let productNotificationStorage: any ProductNotificationStorage
  
  init(productNotificationStorage: any ProductNotificationStorage) {
    self.productNotificationStorage = productNotificationStorage
  }
  
  func saveProuctNotification(productNotification: ProductNotification) -> AnyPublisher<Void, any Error> {
    return self.productNotificationStorage.saveProductNotification(productNotification: productNotification)
  }
  
  func fetchProductNotifications() -> AnyPublisher<[ProductNotification], any Error> {
    return productNotificationStorage.fetchProductNotifications()
  }
}
