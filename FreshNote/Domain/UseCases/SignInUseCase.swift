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
  
  init(appleSignInRepository: any AppleSignInRepository) {
    self.appleSignInRepository = appleSignInRepository
  }
  
  func signIn(
    authProvider: AuthenticationProvider
  ) -> AnyPublisher<Void, any Error> {
    switch authProvider {
    case let .apple(idToken, nonce, fullName):
      return self.appleSignInRepository
        .signIn(idToken: idToken, nonce: nonce, fullName: fullName)
    }
  }
}
