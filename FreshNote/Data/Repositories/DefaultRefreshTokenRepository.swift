//
//  DefaultRefreshTokenRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 1/20/25.
//

import Combine
import Foundation

final class DefaultRefreshTokenRepository: RefreshTokenRepository {
  private let refreshTokenStorage: any RefreshTokenStorage
  
  init(refreshTokenStorage: any RefreshTokenStorage) {
    self.refreshTokenStorage = refreshTokenStorage
  }
  
  func saveRefreshToken(refreshToken: String) -> AnyPublisher<Void, any Error> {
    self.refreshTokenStorage
      .saveRefreshToken(refreshToken)
  }
  
  func fetchRefreshToken() -> AnyPublisher<String, any Error> {
    self.refreshTokenStorage
      .fetchRefreshToken()
  }
  
  func deleteRefreshToken() -> AnyPublisher<Void, any Error> {
    self.refreshTokenStorage
      .deleteRefreshToken()
  }
}
