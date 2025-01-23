//
//  UserProfileRequestDTO.swift
//  FreshNote
//
//  Created by SeokHyun on 12/17/24.
//

import Foundation

struct UserProfileRequestDTO: Encodable {
  let name: String
  let imageURLString: String?
}
