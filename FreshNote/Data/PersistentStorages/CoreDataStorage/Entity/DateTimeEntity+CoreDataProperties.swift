//
//  DateTimeEntity+CoreDataProperties.swift
//  FreshNote
//
//  Created by SeokHyun on 1/11/25.
//
//

import Foundation
import CoreData


extension DateTimeEntity {
  @nonobjc public class func fetchRequest() -> NSFetchRequest<DateTimeEntity> {
    return NSFetchRequest<DateTimeEntity>(entityName: DateTimeEntity.entityName)
  }
  
  @NSManaged public var date: Int16
  @NSManaged public var hour: Int16
  @NSManaged public var minute: Int16
  
  enum PropertyName: String {
    case date
    case hour
    case minute
  }
}

extension DateTimeEntity: Identifiable { }
