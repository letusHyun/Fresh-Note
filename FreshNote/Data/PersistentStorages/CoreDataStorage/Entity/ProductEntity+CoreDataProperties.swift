//
//  ProductEntity+CoreDataProperties.swift
//  FreshNote
//
//  Created by SeokHyun on 12/12/24.
//
//

import Foundation
import CoreData

extension ProductEntity {
  @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductEntity> {
    return NSFetchRequest<ProductEntity>(entityName: ProductEntity.entityName)
  }
  
  @NSManaged public var imageURLString: String?
  @NSManaged public var name: String
  @NSManaged public var expirationDate: Date
  @NSManaged public var category: String
  @NSManaged public var memo: String?
  @NSManaged public var isPinned: Bool
  @NSManaged public var didString: String
  @NSManaged public var createdAt: Date
  
  enum PropertyName: String {
    case imageURLString
    case name
    case expirationDate
    case category
    case memo
    case isPinned
    case didString
    case createdAt
  }
}

extension ProductEntity : Identifiable { }
