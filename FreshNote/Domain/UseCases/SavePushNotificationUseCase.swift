//
//  SavePushNotificationUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 1/10/25.
//

import Combine
import Foundation

enum SavePushNotificationUseCaseError: Error {
  case invalidDate
  case referenceError
}

protocol SavePushNotificationUseCase {
  /// 제품을 추가하는 경우 알림을 추가함
  func saveNotification(product: Product) -> AnyPublisher<Void, any Error>
}

final class DefaultSavePushNotificationUseCase: SavePushNotificationUseCase {
  private let fetchDateTimeUseCase: any FetchDateTimeUseCase
  private let pushNotificationRepository: any PushNotificationRepository
  
  init(
    fetchDateTimeUseCase: any FetchDateTimeUseCase,
    pushNotificationRepository: any PushNotificationRepository
  ) {
    self.fetchDateTimeUseCase = fetchDateTimeUseCase
    self.pushNotificationRepository = pushNotificationRepository
  }
  
  func saveNotification(product: Product) -> AnyPublisher<Void, any Error> {
    self.fetchDateTimeUseCase.execute()
      .tryMap { [weak self] dateTime -> (DateTime, Date) in
        guard let self else { throw SavePushNotificationUseCaseError.referenceError }
        
        let notificationDate = try self.makeNotificationDate(
          dateTime: dateTime,
          expirationDate: product.expirationDate
        )
        return (dateTime, notificationDate)
      }
      .flatMap { [weak self] tuple -> AnyPublisher<Void, any Error> in
        guard let self else { return Empty().eraseToAnyPublisher() }
        
        let (dateTime, notificationDate) = tuple
        
        // 알림시간이 현재보다 과거인지 검증
        if notificationDate <= Date() {
          return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        }
        let requestEntity = UNNotificationRequestEntity(
          noficationID: product.did,
          productName: product.name,
          remainingDay: dateTime.date,
          date: notificationDate
        )
        return self.pushNotificationRepository
          .scheduleNotification(requestEntity: requestEntity)
      }
      .eraseToAnyPublisher()
  }
}


// MARK: - Private
extension DefaultSavePushNotificationUseCase {
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
}
