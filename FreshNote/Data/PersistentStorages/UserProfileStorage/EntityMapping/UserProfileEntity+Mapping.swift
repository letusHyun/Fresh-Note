//
//  UserProfileEntity+Mapping.swift
//  FreshNote
//
//  Created by SeokHyun on 12/13/24.
//

import CoreData
import Foundation

extension UserProfileEntity {
  convenience init(userProfile: UserProfile, insertInto context: NSManagedObjectContext) {
    self.init(context: context)
    self.name = userProfile.name
    
    guard let url = userProfile.imageURL else {
      self.imageURLString = nil
      return
    }
    self.imageURLString = url.absoluteString
  }
}

// MARK: - Mapping To Domain
extension UserProfileEntity {
  func toDomain() -> UserProfile {
    let imageURL = self.imageURLString.flatMap { URL(string: $0) }
    return UserProfile(
      name: self.name,
      imageURL: imageURL
    )
  }
}
