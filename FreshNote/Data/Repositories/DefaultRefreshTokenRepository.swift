//
//  DefaultRefreshTokenRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 1/21/25.
//

import Combine
import Foundation

enum RefreshTokenRepositoryError: Error {
  case encodingError
  case invalidResponse
}

final class DefaultRefreshTokenRepository: RefreshTokenRepository {
  private let dataTransferService: any DataTransferService
  private let backgroundQueue: DispatchQueue
  private let cache: any RefreshTokenStorage
  private let buildConfiguration: String
  
  init(
    dataTransferService: any DataTransferService,
    backgroundQueue: DispatchQueue = .global(qos: .userInitiated),
    cache: any RefreshTokenStorage,
    buildConfiguration: String
  ) {
    self.dataTransferService = dataTransferService
    self.backgroundQueue = backgroundQueue
    self.cache = cache
    self.buildConfiguration = buildConfiguration
  }
  
  func revokeRefreshToken() -> AnyPublisher<Void, any Error> {
    return self.fetchRefreshToken()
      .flatMap { [weak self] tokenString -> AnyPublisher<Void, any Error> in
        guard let self else {
          return Fail(error: RefreshTokenRepositoryError.encodingError).eraseToAnyPublisher()
        }
        
        let requestDTO = RefreshTokenRevokeRequestDTO(refreshToken: tokenString, buildConfiguration: self.buildConfiguration)
        
        let endpoint = APIEndpoints.revokeRefreshToken(with: requestDTO)
        
        return self.dataTransferService
          .request(with: endpoint, on: self.backgroundQueue)
          .map { _ in }
          .mapError { $0 as Error }
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
  
  func issuedFirstRefreshToken(with code: Data) -> AnyPublisher<RefreshToken, any Error> {
    guard let codeString = String(data: code, encoding: .utf8) else {
      return Fail(error: RefreshTokenRepositoryError.encodingError).eraseToAnyPublisher()
    }
    
    let requestDTO = RefreshTokenRequestDTO(
      code: codeString,
      buildConfiguration: self.buildConfiguration
    )
    let endpoint = APIEndpoints.getRefreshToken(with: requestDTO)
    
    return self.dataTransferService
      .request(with: endpoint, on: self.backgroundQueue)
      .tryMap { responseDTO in
        guard let responseDTO = responseDTO else {
          throw RefreshTokenRepositoryError.invalidResponse
        }
        return responseDTO.toDomain()
      }
      .mapError { $0 as Error }
      .eraseToAnyPublisher()
  }
  
  func saveRefreshToken(refreshToken: RefreshToken) -> AnyPublisher<Void, any Error> {
    self.cache.saveRefreshToken(refreshToken.tokenString)
  }
  
  func fetchRefreshToken() -> AnyPublisher<String, any Error> {
    self.cache.fetchRefreshToken()
  }
  
  func deleteRefreshToken() -> AnyPublisher<Void, any Error> {
    self.cache.deleteRefreshToken()
  }
  
  func isSavedRefreshToken() -> AnyPublisher<Bool, any Error> {
    self.cache
      .fetchRefreshToken()
      .map { _ in return true }
      .catch { error in
        // storage에 데이터 존재하지 않으면 false 반환
        if case KeychainRefreshTokenStorageError.noData = error {
          return Just(false)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        }
        return Fail(error: error)
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
}
