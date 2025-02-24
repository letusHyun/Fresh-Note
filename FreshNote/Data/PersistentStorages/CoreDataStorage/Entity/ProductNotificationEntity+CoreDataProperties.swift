//
//  ProductNotificationEntity+CoreDataProperties.swift
//  FreshNote
//
//  Created by SeokHyun on 1/15/25.
//
//

import Foundation
import CoreData

extension ProductNotificationEntity {
  
  @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductNotificationEntity> {
    return NSFetchRequest<ProductNotificationEntity>(entityName: ProductNotificationEntity.entityName)
  }
  
  @NSManaged public var title: String
  @NSManaged public var remainingDay: Int16
  @NSManaged public var isViewed: Bool
  
  enum PropertyName: String {
    case title
    case remainingDay
    case isViewed
  }
}

extension ProductNotificationEntity : Identifiable {
  
}
