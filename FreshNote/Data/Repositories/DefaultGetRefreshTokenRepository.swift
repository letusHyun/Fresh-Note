//
//  DefaultGetRefreshTokenRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 1/21/25.
//

import Combine
import Foundation

enum GetRefreshTokenRepositoryError: Error {
  case encodingError
}

final class DefaultGetRefreshTokenRepository: GetRefreshTokenRepository {
  private let dataTransferService: any DataTransferService
  private let backgroundQueue: DispatchQueue
  
  init(
    dataTransferService: any DataTransferService,
    backgroundQueue: DispatchQueue = .global(qos: .userInitiated)
  ) {
    self.dataTransferService = dataTransferService
    self.backgroundQueue = backgroundQueue
  }
  
  func execute(with code: Data) -> AnyPublisher<RefreshToken, any Error> {
    guard let codeString = String(data: code, encoding: .utf8) else {
      return Fail(error: GetRefreshTokenRepositoryError.encodingError).eraseToAnyPublisher()
    }
    
    let requestDTO = RefreshTokenRequestDTO(code: codeString)
    let endpoint = APIEndpoints.getRefreshToken(with: requestDTO)
    
    return self.dataTransferService
      .request(with: endpoint, on: self.backgroundQueue)
      .map { $0.toDomain() }
      .mapError { $0 as Error }
      .eraseToAnyPublisher()
  }
}
