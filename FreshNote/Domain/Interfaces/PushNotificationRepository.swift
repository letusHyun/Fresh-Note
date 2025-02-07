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
  
  /// 로컬 푸시 알림들의 재등록 여부를 판별합니다.
  ///
  /// 로컬 푸시 알림들을 재등록 해야 한다면 true, 재등록 하지 않아야 한다면 false를 반환합니다.
//  func shouldReRegisterNotifications() -> AnyPublisher<Bool, any Error>
  func deleteNotificaion(notificationIDs: [DocumentID])
}
