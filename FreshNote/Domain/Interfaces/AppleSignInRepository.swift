//
//  AppleSignInRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 12/13/24.
//

import FirebaseAuth
import Combine
import Foundation

protocol AppleSignInRepository {
  func signIn(
    idToken: String,
    nonce: String,
    fullName: PersonNameComponents?
  ) -> AnyPublisher<Void, any Error>
}
