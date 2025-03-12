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
  func issuedFirstRefreshToken(with code: Data) -> AnyPublisher<RefreshToken, any Error> {
    
  }
  
  func revokeRefreshToken() -> AnyPublisher<Void, any Error> {
    
  }
  
  func saveRefreshToken(refreshToken: RefreshToken) -> AnyPublisher<Void, any Error> {
    
  }
  
  func fetchRefreshToken() -> AnyPublisher<String, any Error> {
    
  }
  
  func isSavedRefreshToken() -> AnyPublisher<Bool, any Error> {
    
  }
  
  func deleteRefreshToken() -> AnyPublisher<Void, any Error> {
    
  }
}
