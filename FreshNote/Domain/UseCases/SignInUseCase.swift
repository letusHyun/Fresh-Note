//
//  SignInUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 12/13/24.
//

import Combine
import Foundation

protocol SignInUseCase {
  /// 로그인을 수행합니다.
  func signIn(
    authProvider: AuthenticationProvider
  ) -> AnyPublisher<Void, any Error>
}

final class DefaultSignInUseCase: SignInUseCase {
  private let appleSignInRepository: any AppleSignInRepository
  private let getRefreshTokenRepository: any GetRefreshTokenRepository
  private let refreshTokenCacheRepository: any RefreshTokenCacheRepository
  
  init(
    appleSignInRepository: any AppleSignInRepository,
    getRefreshTokenRepository: any GetRefreshTokenRepository,
    refreshTokenCacheRepository: any RefreshTokenCacheRepository
  ) {
    self.appleSignInRepository = appleSignInRepository
    self.getRefreshTokenRepository = getRefreshTokenRepository
    self.refreshTokenCacheRepository = refreshTokenCacheRepository
  }
  
  func signIn(
    authProvider: AuthenticationProvider
  ) -> AnyPublisher<Void, any Error> {
    switch authProvider {
    case let .apple(idToken, nonce, fullName, authorizationCode):
      
      return self.appleSignInRepository
        .signIn(idToken: idToken, nonce: nonce, fullName: fullName)
        .flatMap { [weak self] () -> AnyPublisher<RefreshToken, any Error> in
          guard let self else { return Empty().eraseToAnyPublisher() }
          
          // 파베 로그인 완료 후, network를 통해 refreshToken 가져옵니다.
          return self.getRefreshTokenRepository
            .execute(with: authorizationCode)
        }
        .flatMap { [weak self] refreshToken -> AnyPublisher<Void, any Error> in
          guard let self else { return Empty().eraseToAnyPublisher() }
          
          // refreshToken을 cache에 저장합니다.
          return self.refreshTokenCacheRepository
            .saveRefreshToken(refreshToken: refreshToken)
        }
        .eraseToAnyPublisher()
    }
  }
}
