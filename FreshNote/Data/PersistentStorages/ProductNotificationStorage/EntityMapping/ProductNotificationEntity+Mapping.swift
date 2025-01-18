//
//  ProductNotificationEntity+Mapping.swift
//  FreshNote
//
//  Created by SeokHyun on 1/15/25.
//

import CoreData
import Foundation

extension ProductNotificationEntity {
  convenience init(
    productNotification: ProductNotification,
    insertInto context: NSManagedObjectContext
  ) {
    self.init(context: context)
    
    self.title = productNotification.productName
    self.remainingDay = Int16(productNotification.remainingDay)
    self.isViewed = productNotification.isViewed
  }
}

extension ProductNotificationEntity {
  func toDomain() -> ProductNotification {
    return ProductNotification(
      productName: self.title,
      remainingDay: Int(self.remainingDay),
      isViewed: self.isViewed
    )
  }
}
