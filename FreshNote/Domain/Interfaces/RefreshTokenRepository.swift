//
//  RefreshTokenRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 1/21/25.
//

import Combine
import Foundation

protocol RefreshTokenRepository {
  /// 외부 api로부터 refresh token을 가져옵니다.
  func issuedFirstRefreshToken(with code: Data) -> AnyPublisher<RefreshToken, any Error>
  
  func revokeRefreshToken() -> AnyPublisher<Void, any Error>
  
  func saveRefreshToken(refreshToken: RefreshToken) -> AnyPublisher<Void, any Error>
  
  /// token을 fetch합니다. token이 존재하지 않으면 nil을 반환합니다.
  func fetchRefreshToken() -> AnyPublisher<String, any Error>
  /// cache 또는 외부 api로부터 refresh token의 저장 여부를 판별합니다.
  func isSavedRefreshToken() -> AnyPublisher<Bool, any Error>
  func deleteRefreshToken() -> AnyPublisher<Void, any Error>
}
