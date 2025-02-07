//
//  RefreshTokenStorage.swift
//  FreshNote
//
//  Created by SeokHyun on 1/20/25.
//

import Combine
import Foundation

protocol RefreshTokenStorage {
  func saveRefreshToken(_ refreshToken: String) -> AnyPublisher<Void, any Error>
  func deleteRefreshToken() -> AnyPublisher<Void, any Error>
  /// refresh token을 가져옵니다.
  func fetchRefreshToken() -> AnyPublisher<String, any Error>
}
