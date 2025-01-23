//
//  UserProfileResponseDTO.swift
//  FreshNote
//
//  Created by SeokHyun on 12/17/24.
//

import Foundation

struct UserProfileResponseDTO: Decodable {
  let name: String
  let imageURLString: String?
}

extension UserProfileResponseDTO {
  func toDomain() -> UserProfile {
    let imageURL = self.imageURLString.flatMap { URL(string: $0) }
    
    return UserProfile(
      name: self.name,
      imageURL: imageURL
    )
  }
}
