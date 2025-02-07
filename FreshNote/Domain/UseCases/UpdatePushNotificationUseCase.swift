//
//  UpdatePushNotificationUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 1/15/25.
//

import Combine
import Foundation

/// 푸시 알림을 변경할 때 사용하는 UseCase입니다.
protocol UpdatePushNotificationUseCase {
  /// 특정 제품 알림 업데이트(제품의 유통기한 수정되면 호출되는 메소드)
  ///
  /// 이 메소드 내에서 검증 실패 시, 알림을 삭제할 수도 있음
  func updateNotification(product: Product) -> AnyPublisher<Void, any Error>
  
  /// 전 제품 알림 업데이트(d-day 변경되면 반드시 호출되는 메소드)
  /// dateTime이 변경될 때 호출되는 메소드
  /// 이 메소드 내에서 검증 실패 시, 알림을 삭제할 수도 있음
  func updateNotifications() -> AnyPublisher<Void, any Error>
}

final class DefaultUpdatePushNotificationUseCase: UpdatePushNotificationUseCase {
  private let savePushNotificationUseCase: any SavePushNotificationUseCase
  private let deletePushNotificationUseCase: any DeletePushNotificationUseCase
  
  private let fetchProductUseCase: (any FetchProductUseCase)?
  
  /// 단일 로컬 알림 update
  init(
    savePushNotificationUseCase: any SavePushNotificationUseCase,
    deletePushNotificationUseCase: any DeletePushNotificationUseCase
  ) {
    self.savePushNotificationUseCase = savePushNotificationUseCase
    self.deletePushNotificationUseCase = deletePushNotificationUseCase
    self.fetchProductUseCase = nil
  }
  
  /// 모든 로컬 알림 update
  init(
    savePushNotificationUseCase: any SavePushNotificationUseCase,
    deletePushNotificationUseCase: any DeletePushNotificationUseCase,
    fetchProductUseCase: any FetchProductUseCase
  ) {
    self.savePushNotificationUseCase = savePushNotificationUseCase
    self.deletePushNotificationUseCase = deletePushNotificationUseCase
    self.fetchProductUseCase = fetchProductUseCase
  }
  
  func updateNotification(product: Product) -> AnyPublisher<Void, any Error> {
    self.deletePushNotificationUseCase
      .deleteNotification(productID: product.did)
      
    return self.savePushNotificationUseCase
      .saveNotification(product: product)
  }
  
  func updateNotifications() -> AnyPublisher<Void, any Error> {
    guard let fetchProductUseCase = self.fetchProductUseCase else {
      return Fail<Void, any Error>(error: CommonError.referenceError).eraseToAnyPublisher()
    }
    
    return fetchProductUseCase
      .fetchProducts()
      .flatMap { [weak self] products -> AnyPublisher<Void, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        let productIDs = products.map { $0.did }
        self.deletePushNotificationUseCase
          .deleteAllNotifications(productIDs: productIDs)
        
        return Publishers
          .Sequence(sequence: products)
          .flatMap(maxPublishers: .max(3)) { [weak self] product -> AnyPublisher<Void, any Error> in
            guard let self else {
              return Fail<Void, any Error>(error: CommonError.referenceError).eraseToAnyPublisher()
            }
            
            return self.savePushNotificationUseCase
              .saveNotification(product: product)
          }
          .collect()
          .map { _ in }
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
}
