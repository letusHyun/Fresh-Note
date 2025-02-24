//
//  DeleteCacheUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 1/26/25.
//

import Combine
import Foundation

enum DeleteCacheUseCaseError: Error {
  case noProductIDs
}

/// 모든 캐싱 데이터를 삭제하는 UseCase입니다.
protocol DeleteCacheUseCase {
  func execute() -> AnyPublisher<Void, any Error>
}

final class DefaultDeleteCacheUseCase: DeleteCacheUseCase {
  // MARK: - Properties
  private let productRepository: any ProductRepository
  private let dateTimeRepository: any DateTimeRepository
  private let productQueryRepository: any ProductQueriesRepository
  private let pushNotificationRepository: any PushNotificationRepository
  
  private var productIDs: [DocumentID]?
  
  // MARK: - LifeCycle
  init(
    productRepository: any ProductRepository,
    dateTimeRepository: any DateTimeRepository,
    productQueryRepository: any ProductQueriesRepository,
    pushNotificationRepository: any PushNotificationRepository
  ) {
    self.productRepository = productRepository
    self.dateTimeRepository = dateTimeRepository
    self.productQueryRepository = productQueryRepository
    self.pushNotificationRepository = pushNotificationRepository
  }
  
  func execute() -> AnyPublisher<Void, any Error> {
    self.productRepository
      .deleteCachedProducts() // product cache delete
      .flatMap { [weak self] productIDs in
        guard let self else {
          return Fail<Void, any Error>(error: CommonError.referenceError).eraseToAnyPublisher()
        }
        
        self.productIDs = productIDs
        
        return self.dateTimeRepository.deleteCachedDateTime() // dateTime cache delete
      }
      .flatMap { [weak self] in
        guard let self else {
          return Fail<Void, any Error>(error: CommonError.referenceError).eraseToAnyPublisher()
        }
        
        return self.productQueryRepository.deleteQueries() // productQuery cache delete
      }
      .flatMap { [weak self] in
        guard let self,
              let productIDs = self.productIDs else {
          return Fail<Void, any Error>(error: DeleteCacheUseCaseError.noProductIDs).eraseToAnyPublisher()
        }
        
        return Future { promise in // push notification delete
          self.pushNotificationRepository.deleteNotificaion(notificationIDs: productIDs)
          
          return promise(.success(()))
        }
        .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
}
