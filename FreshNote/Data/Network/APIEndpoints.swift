//
//  APIEndpoints.swift
//  FreshNote
//
//  Created by SeokHyun on 1/22/25.
//

import Foundation

struct APIEndpoints {
  static func getRefreshToken(
    with requestDTO: RefreshTokenRequestDTO
  ) -> Endpoint<RefreshTokenResponseDTO> {
    .init(
      path: "getRefreshToken",
      queryParametersEncodable: requestDTO
    )
  }
  
  static func revokeRefreshToken(
    with requestDTO: RefreshTokenRevokeRequestDTO
  ) -> Endpoint<RefreshTokenRevokeResponseDTO> {
    .init(
      path: "revokeToken",
      queryParametersEncodable: requestDTO
    )
  }
}
