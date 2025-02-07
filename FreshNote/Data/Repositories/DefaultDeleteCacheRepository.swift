//
//  DefaultDeleteCacheRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 2/4/25.
//

import Combine
import Foundation

protocol DeleteCacheRepository {
  func deleteCaches() -> AnyPublisher<Void, any Error>
}

final class DefaultDeleteCacheRepository: DeleteCacheRepository {
  private let productStorage: any ProductStorage
  private let dateTimeStorage: any DateTimeStorage
  private let productQueryStorage: any ProductQueryStorage
  
  init(
    productStorage: any ProductStorage,
    dateTimeStorage: any DateTimeStorage,
    productQueryStorage: any ProductQueryStorage
  ) {
    self.productStorage = productStorage
    self.dateTimeStorage = dateTimeStorage
    self.productQueryStorage = productQueryStorage
  }
  
  func deleteCaches() -> AnyPublisher<Void, any Error> {
    self.productStorage
      .deleteAll()
      .flatMap { [weak self] _ -> AnyPublisher<Void, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        
        return self.dateTimeStorage
          .deleteAll()
      }
      .flatMap { [weak self] _ -> AnyPublisher<Void, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        
        return self.productQueryStorage
          .deleteAll()
      }
      .eraseToAnyPublisher()
  }
}
