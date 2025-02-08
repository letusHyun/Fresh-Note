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
  
  func reauthenticate(
    authProvider: AuthenticationProvider
  ) -> AnyPublisher<Void, any Error>
}

final class DefaultSignInUseCase: SignInUseCase {
  private let firebaseAuthRepository: any FirebaseAuthRepository
  private let refreshTokenRepository: any RefreshTokenRepository
  
  init(
    firebaseAuthRepository: any FirebaseAuthRepository,
    refreshTokenRepository: any RefreshTokenRepository
  ) {
    self.firebaseAuthRepository = firebaseAuthRepository
    self.refreshTokenRepository = refreshTokenRepository
  }
  
  func signIn(
    authProvider: AuthenticationProvider
  ) -> AnyPublisher<Void, any Error> {
    switch authProvider {
    case let .apple(idToken, nonce, fullName, authorizationCode):
      
      // 애플 로그인
      return self.firebaseAuthRepository
        .signIn(idToken: idToken, nonce: nonce, fullName: fullName)
        .flatMap { [weak self] () -> AnyPublisher<RefreshToken, any Error> in
          guard let self else {
            return Fail(error: CommonError.referenceError).eraseToAnyPublisher()
          }
          
          // 파베 로그인 완료 후, network를 통해 refreshToken 가져옵니다.
          return self.refreshTokenRepository
            .issuedFirstRefreshToken(with: authorizationCode)
        }
        .flatMap { [weak self] refreshToken -> AnyPublisher<Void, any Error> in
          guard let self else {
            return Fail(error: CommonError.referenceError).eraseToAnyPublisher()
          }
          
          // refreshToken을 cache에 저장합니다.
          return self.refreshTokenRepository
            .saveRefreshToken(refreshToken: refreshToken)
        }
        .eraseToAnyPublisher()
    }
  }
  
  func reauthenticate(
    authProvider: AuthenticationProvider
  ) -> AnyPublisher<Void, any Error> {
    switch authProvider {
    case let .apple(idToken, nonce, fullName, _):
      return self.firebaseAuthRepository
        .reauthenticate(idToken: idToken, nonce: nonce, fullName: fullName)
    }
  }
}
