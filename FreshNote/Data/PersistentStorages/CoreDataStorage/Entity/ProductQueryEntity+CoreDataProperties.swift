//
//  ProductQueryEntity+CoreDataProperties.swift
//  FreshNote
//
//  Created by SeokHyun on 12/10/24.
//
//

import Foundation
import CoreData

extension ProductQueryEntity {
  @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductQueryEntity> {
    return NSFetchRequest<ProductQueryEntity>(entityName: ProductQueryEntity.entityName)
  }
  
  @NSManaged public var createdAt: Date
  @NSManaged public var keyword: String
  @NSManaged public var uuidString: String
  
  enum PropertyName: String {
    case createdAt
    case keyword
    case uuidString
  }
}

extension ProductQueryEntity : Identifiable { }
