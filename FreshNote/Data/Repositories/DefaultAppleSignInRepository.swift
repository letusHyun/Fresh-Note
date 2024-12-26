//
//  DefaultAppleSignInRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 12/14/24.
//

import FirebaseAuth
import Combine
import Foundation

final class DefaultAppleSignInRepository: AppleSignInRepository {
  func signIn(
    idToken: String,
    nonce: String,
    fullName: PersonNameComponents?
  ) -> AnyPublisher<Void, any Error> {
    let credential = OAuthProvider
      .appleCredential(withIDToken: idToken,
                       rawNonce: nonce,
                       fullName: fullName)
    
    return self.signIn(credential: credential)
  }
  
  // MARK: - Private Helpers
  private func signIn(credential: AuthCredential) -> AnyPublisher<Void, any Error> {
    return Future { promise in
      Auth.auth().signIn(with: credential) { result, error  in
        if let error = error {
          return promise(.failure(error))
        }
        
        guard let _ = result else {
          return promise(.failure(FirebaseUserError.noResult))
        }
        
        return promise(.success(()))
      }
    }
    .eraseToAnyPublisher()
  }
}
