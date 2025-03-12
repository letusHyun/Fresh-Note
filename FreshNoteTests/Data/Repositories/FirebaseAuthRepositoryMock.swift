//
//  FirebaseAuthRepositoryMock.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import Foundation
import Combine

final class FirebaseAuthRepositoryMock: FirebaseAuthRepository {
  private(set) var deleteAccountCalled = false
  private(set) var signInCalled = false
  private(set) var signOutCalled = false
  private(set) var checkSignOutStateCalled = false
  private(set) var reauthenticateCalled = false
  
  var deleteAccountResult: AnyPublisher<Void, any Error>!
  var signInResult: AnyPublisher<Void, any Error>!
  var signOutResult: AnyPublisher<Void, any Error>!
  var checkSignOutStateResult: AnyPublisher<Bool, Never>!
  var reauthenticateResult: AnyPublisher<Void, any Error>!
  
  func deleteAccount() -> AnyPublisher<Void, any Error> {
    self.deleteAccountCalled = true
    return self.deleteAccountResult
  }
  
  func signIn(
    idToken: String,
    nonce: String, fullName: PersonNameComponents?
  ) -> AnyPublisher<Void, any Error> {
    self.signInCalled = true
    return self.signInResult
  }
  
  func signOut() -> AnyPublisher<Void, any Error> {
    self.signOutCalled = true
    return self.signInResult
  }
  
  func checkSignOutState() -> AnyPublisher<Bool, Never> {
    self.checkSignOutStateCalled = true
    return self.checkSignOutStateResult
  }
  
  func reauthenticate(
    idToken: String,
    nonce: String,
    fullName: PersonNameComponents?
  ) -> AnyPublisher<Void, any Error> {
    self.reauthenticateCalled = true
    return self.reauthenticateResult
  }
}
