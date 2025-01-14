//
//  CheckRestorePushNotificationsUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 1/14/25.
//

import Combine
import Foundation

/// 푸시 알림의 restore 여부를 판별하는 UseCase입니다.
protocol CheckRestorePushNotificationsUseCase {
  func execute() -> AnyPublisher<Bool, any Error>
}

final class DefaultCheckRestorePushNotificationsUseCase: CheckRestorePushNotificationsUseCase {
  private let productRepository: any ProductRepository
  private let pushNotificationRepository: any PushNotificationRepository
  
  init(
    productRepository: any ProductRepository,
    pushNotificationRepository: any PushNotificationRepository
  ) {
    self.productRepository = productRepository
    self.pushNotificationRepository = pushNotificationRepository
  }
  
  func execute() -> AnyPublisher<Bool, any Error> {
    // 제품이 local에 저장됐는지 판별합니다.
    return self.productRepository
      .isSavedProductInLocal()
      .flatMap { [weak self] isSavedProductInLocal -> AnyPublisher<Bool, any Error> in
        guard let self else { return Empty().eraseToAnyPublisher() }
        
        if isSavedProductInLocal {
          // 푸시 알림이 저장되어있는지 판별합니다.
          return self.pushNotificationRepository
            .shouldReRegisterNotifications()
            .map { shouldRegister -> Bool in
              return shouldRegister ? true : false
            }
            .eraseToAnyPublisher()
        }
        return Just(false)
          .setFailureType(to: Error.self)
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
}
