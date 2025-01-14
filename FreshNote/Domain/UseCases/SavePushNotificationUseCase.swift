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
  func saveProductNotification(product: Product) -> AnyPublisher<Void, any Error>
  // / 특정 제품 알림 업데이트(제품의 유통기한 수정되면 호출되는 메소드)
  // / 이 메소드 내에서 검증 실패 시, 알림을 삭제할 수도 있음
  //  func updateNotification(product: Product) -> AnyPublisher<Void, any Error>
  //  /// 전 제품 알림 업데이트(d-day 변경되면 반드시 호출되는 메소드)
  //  /// 이 메소드 내에서 검증 실패 시, 알림을 삭제할 수도 있음
  //  func updateNotifications(products: [Product]) -> AnyPublisher<Void, any Error>
  //  /// 제품 삭제 시, 알림 삭제하는 메소드
  //  /// 또는 검증 실패 시, 호출하는 경우도 존재함
  //  func removeProductNotification(product: Product) -> AnyPublisher<Void, any Error>
  //
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
  
  
  
  func saveProductNotification(product: Product) -> AnyPublisher<Void, any Error> {
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
/// 업데이트
//  func updateNotifications(products: [Product]) -> AnyPublisher<Void, any Error> {
//    // 1. 전체 알림 리밸런싱
//    // 2. 리밸런싱 후 전체 알림 업데이트
//  }
//
//  func updateNotification(product: Product) -> AnyPublisher<Void, any Error> {
//    // 1. 특정 알림 리밸런싱
//    // 2. 리밸런싱 후, 특정 알림 알림 업데이트
//  }
//
//  /// 알림 추가
//  func scheduleProductNotification(product: Product) -> AnyPublisher<Bool, any Error> {
//    // 1. 알림 날짜 계산
//    // 2. 푸시 알림 일자가 현재보다 과거인지 검증
//
//    // 3. 알림 내용 구성
//    // 4. 알림 예약 요청 및 결과 변환
//  }
//
//  /// 특정 알림 업데이트(리밸런싱 반드시 필요)
//
//  func removeProductNotification(product: Product) -> AnyPublisher<Void, any Error> {
//    <#code#>
//  }

