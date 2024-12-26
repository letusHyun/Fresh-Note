//
//  DefaultSignInStateRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 12/15/24.
//

import FirebaseAuth
import Combine
import Foundation
import AuthenticationServices

enum SignInError: Error {
  case tokenValidationFailed(Error)
  case noAppleCredential
  case appleAuthorizationFailed(Error)
  case noAuthorized
  case failedToCheck
}

final class DefaultSignInStateRepository: SignInStateRepository {
  private let signInStateStorage: any SignInStateStorage
  private var subscriptions = Set<AnyCancellable>()
  
  
  init(signInStateStorage: any SignInStateStorage) {
    self.signInStateStorage = signInStateStorage
  }
  
  func checkSignIn() -> AnyPublisher<Bool, any Error> {
    return self.signInStateStorage.fetchSignInState()
      .flatMap { isSignedIn in
        guard isSignedIn, let currentUser = Auth.auth().currentUser else {
          // 로그인 한 적 없다면
          return Just(isSignedIn)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        }
        
        // 로그인 한 적 있다면
        return Future<Bool, any Error> { [weak self] promise in
          guard let self else { return promise(.success(false)) }
          
          currentUser.getIDToken { token, error in
            if let error = error {
              self.handleTokenError(promise: promise); return
            } else {
              return promise(.success((true)))
            }
          }
        }
        .flatMap { [weak self] isTokenValid -> AnyPublisher<Bool, any Error> in
          guard let self else { return Empty().eraseToAnyPublisher() }
          
          guard let appleCredential = currentUser.providerData.first(where: { $0.providerID == "apple.com" }) else {
            return self.signInStateStorage
              .updateSignInState(updateToValue: false)
              .map { _ in false }
              .eraseToAnyPublisher()
          }
          
          return self.validateAppleCredential(userID: appleCredential.uid)
        }
        .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
  
  func updateSignInState(updateToValue: Bool) -> AnyPublisher<Void, any Error> {
    return self.signInStateStorage.updateSignInState(updateToValue: updateToValue)
  }
  
  func saveSignInState() -> AnyPublisher<Void, any Error> {
    return self.signInStateStorage.saveSignInState()
  }
  
  // MARK: - Private
  /// storage error만 error로 보내고 상위 error는 false value로 전달합니다.
  private func handleTokenError(promise: @escaping Future<Bool, any Error>.Promise) {
    let notSignedIn = false
    
    self.signInStateStorage
      .updateSignInState(updateToValue: notSignedIn)
      .map { _ in
        try? Auth.auth().signOut(); return
      }
      .sink { completion in
        switch completion {
        case .finished:
          promise(.success(notSignedIn))
        case .failure(let storageError):
          promise(.failure(storageError))
        }
      } receiveValue: { _ in }
      .store(in: &self.subscriptions)
  }
  
  private func validateAppleCredential(userID: String) -> AnyPublisher<Bool, any Error> {
    return Future<Bool, any Error> { promise in
      let appleIDProvider = ASAuthorizationAppleIDProvider()
      appleIDProvider.getCredentialState(forUserID: userID) { state, error in
        if error != nil || state != .authorized {
          promise(.success(false))
          return
        }
        promise(.success(true))
      }
    }
    .flatMap { [weak self] isAuthorized -> AnyPublisher<Bool, any Error> in
      guard let self else { return Just(false).setFailureType(to: Error.self).eraseToAnyPublisher() }
      
      // credential 인증 실패 시, localDB의 signInState update
      if !isAuthorized {
        return self.signInStateStorage
          .updateSignInState(updateToValue: false)
          .map { _ in false }
          .eraseToAnyPublisher()
      }
      
      return Just(true)
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }
    .eraseToAnyPublisher()
  }
}
