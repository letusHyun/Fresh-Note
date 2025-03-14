//
//  RefreshTokenRepositoryMock.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import Combine
import Foundation

final class RefreshTokenRepositoryMock: RefreshTokenRepository {
  private(set) var issuedFirstRefreshTokenCallCount = 0
  private(set) var revokeRefreshTokenCallCount = 0
  private(set) var saveRefreshTokenCallCount = 0
  private(set) var fetchRefreshTokenCallCount = 0
  private(set) var isSavedRefreshTokenCallCount = 0
  private(set) var deleteRefreshTokenCallCount = 0
  
  private(set) var lastAuthorizationCode: Data?
  private(set) var lastSavedRefreshToken: RefreshToken?
  
  var issuedFirstRefreshTokenResult: AnyPublisher<RefreshToken, any Error>!
  var revokeRefreshTokenResult: AnyPublisher<Void, any Error>!
  var saveRefreshTokenResult: AnyPublisher<Void, any Error>!
  var fetchRefreshTokenResult: AnyPublisher<String, any Error>!
  var isSavedRefreshTokenResult: AnyPublisher<Bool, any Error>!
  var deleteRefreshTokenResult: AnyPublisher<Void, any Error>!
  
  func issuedFirstRefreshToken(with code: Data) -> AnyPublisher<RefreshToken, any Error> {
    issuedFirstRefreshTokenCallCount += 1
    lastAuthorizationCode = code
    return issuedFirstRefreshTokenResult
  }
  
  func revokeRefreshToken() -> AnyPublisher<Void, any Error> {
    revokeRefreshTokenCallCount += 1
    return revokeRefreshTokenResult
  }
  
  func saveRefreshToken(refreshToken: RefreshToken) -> AnyPublisher<Void, any Error> {
    saveRefreshTokenCallCount += 1
    lastSavedRefreshToken = refreshToken
    return saveRefreshTokenResult
  }
  
  func fetchRefreshToken() -> AnyPublisher<String, any Error> {
    fetchRefreshTokenCallCount += 1
    return fetchRefreshTokenResult
  }
  
  func isSavedRefreshToken() -> AnyPublisher<Bool, any Error> {
    isSavedRefreshTokenCallCount += 1
    return isSavedRefreshTokenResult
  }
  
  func deleteRefreshToken() -> AnyPublisher<Void, any Error> {
    deleteRefreshTokenCallCount += 1
    return deleteRefreshTokenResult
  }
}
