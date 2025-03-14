//
//  FirebaseAuthRepositoryMock.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import Combine
import Foundation

final class FirebaseAuthRepositoryMock: FirebaseAuthRepository {
  private(set) var signInCallCount = 0
  private(set) var reauthenticateCallCount = 0
  private(set) var signOutCallCount = 0
  private(set) var deleteAccountCallCount = 0
  private(set) var checkSignOutStateCallCount = 0
  
  private(set) var lastIdToken: String?
  private(set) var lastNonce: String?
  private(set) var lastFullName: PersonNameComponents?
  
  var signInResult: AnyPublisher<Void, any Error>!
  var reauthenticateResult: AnyPublisher<Void, any Error>!
  var signOutResult: AnyPublisher<Void, any Error>!
  var deleteAccountResult: AnyPublisher<Void, any Error>!
  var checkSignOutStateResult: AnyPublisher<Bool, Never>!
  
  func signIn(idToken: String, nonce: String, fullName: PersonNameComponents?) -> AnyPublisher<Void, any Error> {
    signInCallCount += 1
    lastIdToken = idToken
    lastNonce = nonce
    lastFullName = fullName
    return signInResult
  }
  
  func reauthenticate(idToken: String, nonce: String, fullName: PersonNameComponents?) -> AnyPublisher<Void, any Error> {
    reauthenticateCallCount += 1
    lastIdToken = idToken
    lastNonce = nonce
    lastFullName = fullName
    return reauthenticateResult
  }
  
  func signOut() -> AnyPublisher<Void, any Error> {
    signOutCallCount += 1
    return signOutResult
  }
  
  func deleteAccount() -> AnyPublisher<Void, any Error> {
    deleteAccountCallCount += 1
    return deleteAccountResult
  }
  
  func checkSignOutState() -> AnyPublisher<Bool, Never> {
    checkSignOutStateCallCount += 1
    return checkSignOutStateResult
  }
}
