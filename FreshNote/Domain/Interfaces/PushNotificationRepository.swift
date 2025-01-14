//
//  PushNotificationRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 1/10/25.
//

import Combine
import Foundation

protocol PushNotificationRepository {
  /// 알림을 추가합니다.
  func scheduleNotification(
    requestEntity: UNNotificationRequestEntity
  ) -> AnyPublisher<Void, any Error>
  
  /// 로컬 푸시 알림의 저장 여부를 확인합니다.
  /// 저장된 적이 있다면 true, 없다면 false를 반환합니다.
  func checkRegisteredNotifications() -> AnyPublisher<Bool, any Error>
}
