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
  /// restore 여부를 판별하고 restore해야하는 경우 restore를 수행합니다.
  func execute(products: [Product]) -> AnyPublisher<Void, any Error>
}

final class DefaultRestorePushNotificationsUseCase: RestorePushNotificationsUseCase {
  private let fetchDateTimeUseCase: any FetchDateTimeUseCase
  private let pushNotificationRepository: any PushNotificationRepository
  private let pushNotiRestorationStateRepository: any PushNotiRestorationStateRepository
  
  init(
    fetchDateTimeUseCase: any FetchDateTimeUseCase,
    pushNotificationRepository: any PushNotificationRepository,
    pushNotiRestorationStateRepository: any PushNotiRestorationStateRepository
  ) {
    self.fetchDateTimeUseCase = fetchDateTimeUseCase
    self.pushNotificationRepository = pushNotificationRepository
    self.pushNotiRestorationStateRepository = pushNotiRestorationStateRepository
  }
  
  func execute(products: [Product]) -> AnyPublisher<Void, any Error> {
    // restore 여부 체크
    return self.shouldRestorePushNotification()
      .flatMap { [weak self] shouldRestore -> AnyPublisher<Void, any Error> in
        // restore
        return self?.handleRestore(shouldRestore: shouldRestore, products: products) ??
        Fail(error: CommonError.referenceError).eraseToAnyPublisher()
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
      return Just(())
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
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
          return Fail(error: RestorePushNotificationsUseCaseError.referenceError)
            .eraseToAnyPublisher()
        }
        // 로컬 알림 재등록
        return self.scheduleNotifications(dateTime: tuple.0, notifications: tuple.1)
      }
      .flatMap { [weak self] _ -> AnyPublisher<Void, any Error> in
        guard let self else {
          return Fail(error: RestorePushNotificationsUseCaseError.referenceError)
            .eraseToAnyPublisher()
        }
        
        return self.pushNotiRestorationStateRepository
          .saveRestoreState(restorationState: .init(shouldRestore: false))
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
          notificationDate: date
        )
        
        return self.pushNotificationRepository
          .scheduleNotification(requestEntity: requestEntity)
      }
      .collect()
      .map { _ in }
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
  
  private func shouldRestorePushNotification() -> AnyPublisher<Bool, any Error> {
    return self.pushNotiRestorationStateRepository
      .fetchRestoreState()
      .map { $0.shouldRestore }
      .eraseToAnyPublisher()
  }
}
