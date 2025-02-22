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
  private let pushNotiRestorationStateRepository: any PushNotiRestorationStateRepository
  
  init(
    firebaseAuthRepository: any FirebaseAuthRepository,
    refreshTokenRepository: any RefreshTokenRepository,
    pushNotiRestorationStateRepository: any PushNotiRestorationStateRepository
  ) {
    self.firebaseAuthRepository = firebaseAuthRepository
    self.refreshTokenRepository = refreshTokenRepository
    self.pushNotiRestorationStateRepository = pushNotiRestorationStateRepository
  }
  
  func signIn(
    authProvider: AuthenticationProvider
  ) -> AnyPublisher<Void, any Error> {
    switch authProvider {
    case let .apple(idToken, nonce, fullName, authorizationCode):
      
      // 애플 로그인
      return self.firebaseAuthRepository
        .signIn(idToken: idToken, nonce: nonce, fullName: fullName)
        .flatMap { [weak self] () -> AnyPublisher<Bool, any Error> in
          guard let self else {
            return Fail(error: CommonError.referenceError).eraseToAnyPublisher()
          }
          
          return self.refreshTokenRepository
            .isSavedRefreshToken()
        }
        .flatMap { [weak self] isSavedRefreshToken -> AnyPublisher<Void, any Error> in
          guard let self else {
            return Fail(error: CommonError.referenceError).eraseToAnyPublisher()
          }
          
          if isSavedRefreshToken { // refresh token이 존재하면 (== 재로그인이라면)
            return self.pushNotiRestorationStateRepository
              .saveRestoreState(restorationState: .init(shouldRestore: true))
          } else { // refresh token이 존재하지 않다면 (== 최초 로그인이라면)
            return self.pushNotiRestorationStateRepository
              .saveRestoreState(restorationState: .init(shouldRestore: false))
              .flatMap {
                self.refreshTokenRepository
                  .issuedFirstRefreshToken(with: authorizationCode)
              }
              .flatMap {
                self.refreshTokenRepository
                  .saveRefreshToken(refreshToken: $0)
              }
              .eraseToAnyPublisher()
          }
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
