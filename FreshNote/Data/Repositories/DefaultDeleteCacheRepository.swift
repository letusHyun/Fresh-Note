//
//  DefaultDeleteCacheRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 2/4/25.
//

import Combine
import Foundation

enum DeleteCacheRepositoryError: Error {
  case noProductIDs
}

final class DefaultDeleteCacheRepository: DeleteCacheRepository {
  private let productStorage: any ProductStorage
  private let dateTimeStorage: any DateTimeStorage
  private let productQueryStorage: any ProductQueryStorage
  
  private var productIDs: [DocumentID]?
  
  init(
    productStorage: any ProductStorage,
    dateTimeStorage: any DateTimeStorage,
    productQueryStorage: any ProductQueryStorage
  ) {
    self.productStorage = productStorage
    self.dateTimeStorage = dateTimeStorage
    self.productQueryStorage = productQueryStorage
  }
  
  func deleteCaches() -> AnyPublisher<[DocumentID], any Error> {
    self.productStorage
      .deleteAll()
      .flatMap { [weak self] productIDs -> AnyPublisher<Void, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        
        self.productIDs = productIDs.compactMap { DocumentID(from: $0) }
        
        return self.dateTimeStorage
          .deleteDateTime()
      }
      .flatMap { [weak self] _ -> AnyPublisher<Void, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        
        return self.productQueryStorage
          .deleteAll()
      }
      .tryMap { [weak self] _ -> [DocumentID] in
        guard let self else { throw CommonError.referenceError }
        guard let productIDs = self.productIDs else { throw DeleteCacheRepositoryError.noProductIDs }
        
        return productIDs
      }
      .eraseToAnyPublisher()
  }
}
