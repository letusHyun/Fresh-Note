//
//  SignOutUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 2/9/25.
//

import Combine
import Foundation

protocol SignOutUseCase {
  func signOut() -> AnyPublisher<Void, any Error>
  func saveRestorationState() -> AnyPublisher<Void, any Error>
}

final class DefaultSignOutUseCase: SignOutUseCase {
  private let firebaseAuthRepository: any FirebaseAuthRepository
  private let pushNotiRestorationStateRepository: any PushNotiRestorationStateRepository
  
  init(
    firebaseAuthRepository: any FirebaseAuthRepository,
    pushNotiRestorationStateRepository: any PushNotiRestorationStateRepository
  ) {
    self.firebaseAuthRepository = firebaseAuthRepository
    self.pushNotiRestorationStateRepository = pushNotiRestorationStateRepository
  }
  
  func signOut() -> AnyPublisher<Void, any Error> {
    self.firebaseAuthRepository
      .signOut()
  }
  
  func saveRestorationState() -> AnyPublisher<Void, any Error> {
    let state = PushNotiRestorationState(shouldRestore: true)
    
    return self.pushNotiRestorationStateRepository
      .saveRestoreState(restorationState: state)
  }
}
