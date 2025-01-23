//
//  RefreshTokenResponseDTO.swift
//  FreshNote
//
//  Created by SeokHyun on 1/22/25.
//

import Foundation

struct RefreshTokenResponseDTO: Decodable {
  let refreshToken: String
  
  enum CodingKeys: String, CodingKey {
    case refreshToken = "refresh_token"
  }
}

extension RefreshTokenResponseDTO {
  func toDomain() -> RefreshToken {
    RefreshToken(tokenString: self.refreshToken)
  }
}
