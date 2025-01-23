//
//  GetRefreshTokenRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 1/21/25.
//

import Combine
import Foundation

/// 외부 api로부터 refresh token을 가져옵니다.
protocol GetRefreshTokenRepository {
  func execute(with code: Data) -> AnyPublisher<RefreshToken, any Error>
}
