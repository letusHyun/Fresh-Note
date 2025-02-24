//
//  CoreDataProductNotificationStorage.swift
//  FreshNote
//
//  Created by SeokHyun on 1/15/25.
//

import CoreData
import Combine
import Foundation

final class CoreDataProductNotificationStorage: ProductNotificationStorage {
  private let coreDataStorage: any CoreDataStorage
  
  init(coreDataStorage: any CoreDataStorage) {
    self.coreDataStorage = coreDataStorage
  }
  
  func saveProductNotification(productNotification: ProductNotification) -> AnyPublisher<Void, any Error> {
    return self.coreDataStorage.performBackgroundTask { context in
      _ = ProductNotificationEntity(productNotification: productNotification, insertInto: context)
      
      do {
        try context.save()
        return
      } catch {
        throw CoreDataStorageError.saveError(error)
      }
    }
  }
  
  func fetchProductNotifications() -> AnyPublisher<[ProductNotification], any Error> {
    return self.coreDataStorage.performBackgroundTask { context in
      let request = ProductNotificationEntity.fetchRequest()
      
      do {
        let productNotifications = try context.fetch(request).map { $0.toDomain() }
        return productNotifications
      } catch {
        throw CoreDataStorageError.readError(error)
      }
    }
  }
}
