//
//  AppleSignInRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 12/13/24.
//

import Combine
import Foundation

/// 외부 api로부터 로그인을 수행합니다.
protocol AppleSignInRepository {
  func signIn(
    idToken: String,
    nonce: String,
    fullName: PersonNameComponents?
  ) -> AnyPublisher<Void, any Error>
}
