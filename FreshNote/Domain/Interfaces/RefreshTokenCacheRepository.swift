//
//  RefreshTokenCacheRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 1/20/25.
//

import Combine
import Foundation

/// Refresh Token의 caching을 담당합니다.
protocol RefreshTokenCacheRepository {
  func saveRefreshToken(refreshToken: RefreshToken) -> AnyPublisher<Void, any Error>
  func fetchRefreshToken() -> AnyPublisher<String, any Error>
  func deleteRefreshToken() -> AnyPublisher<Void, any Error>
}
