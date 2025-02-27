//
//  RefreshTokenRevokeRequestDTO.swift
//  FreshNote
//
//  Created by SeokHyun on 2/2/25.
//

import Foundation

struct RefreshTokenRevokeRequestDTO: Encodable {
  let refreshToken: String
  
  enum CodingKeys: String, CodingKey {
    case refreshToken = "refresh_token"
  }
}
