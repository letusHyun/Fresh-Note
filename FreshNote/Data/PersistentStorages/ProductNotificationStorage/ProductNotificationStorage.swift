//
//  ProductNotificationStorage.swift
//  FreshNote
//
//  Created by SeokHyun on 1/15/25.
//

import Combine
import Foundation

protocol ProductNotificationStorage {
  func saveProductNotification(productNotification: ProductNotification) -> AnyPublisher<Void, any Error>
  func fetchProductNotifications() -> AnyPublisher<[ProductNotification], any Error>
}
