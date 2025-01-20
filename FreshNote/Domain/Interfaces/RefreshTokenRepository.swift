//
//  RefreshTokenRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 1/20/25.
//

import Combine
import Foundation

protocol RefreshTokenRepository {
  func saveRefreshToken(refreshToken: String) -> AnyPublisher<Void, any Error>
  func fetchRefreshToken() -> AnyPublisher<String, any Error>
  func deleteRefreshToken() -> AnyPublisher<Void, any Error>
}
