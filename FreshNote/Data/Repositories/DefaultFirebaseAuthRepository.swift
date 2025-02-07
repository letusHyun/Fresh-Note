//
//  DefaultFirebaseAuthRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 12/14/24.
//

import FirebaseAuth
import Combine
import Foundation
import AuthenticationServices

enum FirebaseAuthRepositoryError: Error {
  case noCurrentUser
  case requireRecentLogin
  case reauthenticateResultError
}

final class DefaultFirebaseAuthRepository: FirebaseAuthRepository {
  // MARK: - Properties
  private let dateTimeCache: any DateTimeStorage
  private let firebaseNetworkService: any FirebaseNetworkService
  
  // MARK: - LifeCycle
  init(
    dateTimeCache: any DateTimeStorage,
    firebaseNetworkService: any FirebaseNetworkService
  ) {
    self.dateTimeCache = dateTimeCache
    self.firebaseNetworkService = firebaseNetworkService
  }
  
  // MARK: - FirebaseAuthRepository
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
  
  func checkSignOutState() -> AnyPublisher<Bool, Never> {
    let isSignOut = Auth.auth().currentUser == nil
    
    return Just(isSignOut)
      .eraseToAnyPublisher()
  }
  
  func signOut() -> AnyPublisher<Void, any Error> {
    do {
      try Auth.auth().signOut()
      return Just(())
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    } catch {
      return Fail(error: error)
        .eraseToAnyPublisher()
    }
  }
  
  func deleteAccount() -> AnyPublisher<Void, any Error> {
    guard let user = Auth.auth().currentUser else {
      return Fail(error: FirebaseAuthRepositoryError.noCurrentUser)
        .eraseToAnyPublisher()
    }
    
    return Future { promise in
      user.delete { error in
        if let error = error {
          let authError = error as NSError
          let isRequireRecentLogin =
          authError.domain == AuthErrorDomain &&
          authError.code == AuthErrorCode.requiresRecentLogin.rawValue
          
          if isRequireRecentLogin {
            return promise(.failure(FirebaseAuthRepositoryError.requireRecentLogin))
          }
          return promise(.failure(error))
        } else {
          return promise(.success(()))
        }
      }
    }
    .eraseToAnyPublisher()
  }
  
  // FIXME: - 여기서 매개변수를 firebase값을 사용하는게 아니라, domain의 entity를 사용해야 함. 그리고 함수 내부에서 변경해주어야 함 고쳐!!!!!!!!!!!!!!!!!!!!!!!!!1
  func reauthenticate(idToken: String, nonce: String, fullName:  PersonNameComponents?) -> AnyPublisher<Void, any Error> {
    guard let user = Auth.auth().currentUser else {
      return Fail(error: FirebaseAuthRepositoryError.noCurrentUser)
        .eraseToAnyPublisher()
    }
    
    let credential = OAuthProvider
      .appleCredential(
        withIDToken: idToken,
        rawNonce: nonce,
        fullName: fullName
      )
    return Future<Void, any Error> { promise in
      user.reauthenticate(with: credential) { result, error in
        if let error = error {
          return promise(.failure(error))
        }
        
        guard (result != nil) else {
          return promise(.failure(FirebaseAuthRepositoryError.reauthenticateResultError))
        }
        return promise(.success(()))
      }
    }
    .eraseToAnyPublisher()
  }
  
  // MARK: - Private
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
