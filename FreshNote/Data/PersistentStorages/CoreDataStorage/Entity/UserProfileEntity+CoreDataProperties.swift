//
//  UserProfileEntity+CoreDataProperties.swift
//  FreshNote
//
//  Created by SeokHyun on 12/13/24.
//
//

import Foundation
import CoreData

extension UserProfileEntity {
  @nonobjc public class func fetchRequest() -> NSFetchRequest<UserProfileEntity> {
    return NSFetchRequest<UserProfileEntity>(entityName: UserProfileEntity.entityName)
  }
  
  @NSManaged public var name: String
  @NSManaged public var imageURLString: String?
  
  enum PropertyName: String {
    case name
    case imageURLString
  }
}

extension UserProfileEntity: Identifiable { }
