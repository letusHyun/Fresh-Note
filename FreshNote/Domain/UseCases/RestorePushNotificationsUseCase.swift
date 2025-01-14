//
//  RestorePushNotificationsUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 1/14/25.
//

import Combine
import Foundation

enum RestorePushNotificationsUseCaseError: Error {
  case referenceError
}

/// 앱을 제거했다가 다시 설치하는 경우, 푸시 알림을 재등록합니다.
protocol RestorePushNotificationsUseCase {
  /// localDB에 products를 저장한 후에 호출해야 합니다.
  func execute(products: [Product]) -> AnyPublisher<Void, any Error>
}

final class DefaultRestorePushNotificationsUseCase: RestorePushNotificationsUseCase {
  private let fetchDateTimeUseCase: any FetchDateTimeUseCase
  private let checkRestorePushNotificationsUseCase: any CheckRestorePushNotificationsUseCase
  private let pushNotificationRepository: any PushNotificationRepository
  
  init(
    fetchDateTimeUseCase: any FetchDateTimeUseCase,
    checkRestorePushNotificationsUseCase: any CheckRestorePushNotificationsUseCase,
    pushNotificationRepository: any PushNotificationRepository
  ) {
    self.fetchDateTimeUseCase = fetchDateTimeUseCase
    self.checkRestorePushNotificationsUseCase = checkRestorePushNotificationsUseCase
    self.pushNotificationRepository = pushNotificationRepository
  }
  
  func execute(products: [Product]) -> AnyPublisher<Void, any Error> {
    guard !products.isEmpty else {
      return self.makeEmptyPublisher()
    }
    
    /// 알림 재등록 여부를 확인합니다.
    return self.checkRestorePushNotificationsUseCase
      .execute()
      .flatMap { [weak self] shouldRestore -> AnyPublisher<Void, any Error> in
        return self?.handleRestore(shouldRestore: shouldRestore, products: products) ??
        Fail(error: RestorePushNotificationsUseCaseError.referenceError).eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
  
  // MARK: - Private
  // 제품의 유통기한과 dateTime을 기반으로 notificationDate를 생성하는 메소드입니다.
  private func makeNotificationDate(dateTime: DateTime, expirationDate: Date) throws -> Date {
    guard let notificationDate = Calendar.current.date(
      byAdding: .day,
      value: -dateTime.date,
      to: expirationDate
    ) else {
      throw SavePushNotificationUseCaseError.invalidDate
    }
    
    var components = Calendar.current.dateComponents([.year, .month, .day], from: notificationDate)
    components.hour = dateTime.hour
    components.minute = dateTime.minute
    
    guard let notificationDate = Calendar.current.date(from: components) else {
      throw SavePushNotificationUseCaseError.invalidDate
    }
    
    return notificationDate
  }
  
  private func handleRestore(shouldRestore: Bool, products: [Product]) -> AnyPublisher<Void, any Error> {
    guard shouldRestore else {
      return self.makeEmptyPublisher()
    }
    
    // 로컴 알림 재등록이 필요한 경우
    
    // dateTime을 가져옵니다.
    return self.fetchDateTimeUseCase.execute()
      .tryMap { [weak self] dateTime -> (DateTime, [(date: Date, product: Product)]) in
        guard let self else { throw RestorePushNotificationsUseCaseError.referenceError }
        
        let notifications = try self.makeNotificationsExceptForInvalidDate(products: products, dateTime: dateTime)
        return (dateTime, notifications)
      }
      .flatMap { [weak self] tuple -> AnyPublisher<Void, any Error> in
        guard let self else {
          return Fail(error: RestorePushNotificationsUseCaseError.referenceError).eraseToAnyPublisher()
        }
        
        return self.scheduleNotifications(dateTime: tuple.0, notifications: tuple.1)
      }
      .eraseToAnyPublisher()
  }
  
  private func scheduleNotifications(
    dateTime: DateTime,
    notifications: [(date: Date, product: Product)]
  ) -> AnyPublisher<Void, any Error> {
    return Publishers.Sequence(sequence: notifications)
      .flatMap(maxPublishers: .max(3)) { [weak self] (date, product) -> AnyPublisher<Void, any Error> in
        guard let self else {
          return Fail(error: RestorePushNotificationsUseCaseError.referenceError).eraseToAnyPublisher()
        }
        let requestEntity = UNNotificationRequestEntity(
          noficationID: product.did,
          productName: product.name,
          remainingDay: dateTime.date,
          date: date
        )
        
        return self.pushNotificationRepository
          .scheduleNotification(requestEntity: requestEntity)
      }
      .collect()
      .map { _ in }
      .eraseToAnyPublisher()
  }
  
  private func makeEmptyPublisher() -> AnyPublisher<Void, any Error> {
    return Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
  }
  
  // 검증 실패한 알림 날짜를 제외하고 notificationDate을 생성합니다.
  private func makeNotificationsExceptForInvalidDate(
    products: [Product],
    dateTime: DateTime
  ) throws -> [(date: Date, product: Product)] {
    return try products.compactMap {
      let notificationDate = try self.makeNotificationDate(
        dateTime: dateTime,
        expirationDate: $0.expirationDate
      )
      
      // 알림시간이 현재보다 과거인지 검증
      return notificationDate > Date() ? (notificationDate, $0) : nil
    }
  }
}
