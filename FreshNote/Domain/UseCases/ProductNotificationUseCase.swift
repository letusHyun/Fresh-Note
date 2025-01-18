//
//  ProductNotificationUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 1/15/25.
//

import Combine
import Foundation

protocol ProductNotificationUseCase {
  func saveProductNotification(_ notification: ProductNotification) -> AnyPublisher<Void, any Error>
  func fetchProductNotifications() -> AnyPublisher<[ProductNotification], any Error>
  // TODO: - update, delete 기능도 추가하기
}

final class DefaultProductNotificaionUseCase: ProductNotificationUseCase {
  private let productNotificationRepository: any ProductNotificationRepository
  
  init(productNotificationRepository: any ProductNotificationRepository) {
    self.productNotificationRepository = productNotificationRepository
  }
  
  func saveProductNotification(_ productNotification: ProductNotification) -> AnyPublisher<Void, any Error> {
    return self.productNotificationRepository.saveProuctNotification(productNotification: productNotification)
  }
  
  func fetchProductNotifications() -> AnyPublisher<[ProductNotification], any Error> {
    return self.productNotificationRepository.fetchProductNotifications()
  }
}
