//
//  RefreshTokenRequestDTO.swift
//  FreshNote
//
//  Created by SeokHyun on 1/22/25.
//

import Foundation

struct RefreshTokenRequestDTO: Encodable {
  let code: String
  let buildConfiguration: String
  
  enum CodingKeys: String, CodingKey {
    case code
    case buildConfiguration = "build_configuration"
  }
}
