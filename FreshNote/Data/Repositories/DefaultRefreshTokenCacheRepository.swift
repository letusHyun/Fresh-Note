//
//  DefaultRefreshTokenCacheRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 1/20/25.
//

import Combine
import Foundation

final class DefaultRefreshTokenCacheRepository: RefreshTokenCacheRepository {
  private let cache: any RefreshTokenStorage
  
  init(
    refreshTokenStorage: any RefreshTokenStorage
  ) {
    self.cache = refreshTokenStorage
  }
  
  func saveRefreshToken(refreshToken: RefreshToken) -> AnyPublisher<Void, any Error> {
    self.cache.saveRefreshToken(refreshToken.tokenString)
  }
  
  func fetchRefreshToken() -> AnyPublisher<String, any Error> {
    self.cache.fetchRefreshToken()
  }
  
  func deleteRefreshToken() -> AnyPublisher<Void, any Error> {
    self.cache.deleteRefreshToken()
  }
}
