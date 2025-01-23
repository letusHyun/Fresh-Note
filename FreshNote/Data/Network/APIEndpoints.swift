//
//  APIEndpoints.swift
//  FreshNote
//
//  Created by SeokHyun on 1/22/25.
//

import Foundation

struct APIEndpoints {
  static func getRefreshToken(
    with refreshTokenRequestDTO: RefreshTokenRequestDTO
  ) -> Endpoint<RefreshTokenResponseDTO> {
    .init(
      path: "getRefreshToken",
      queryParametersEncodable: refreshTokenRequestDTO
    )
  }
}
