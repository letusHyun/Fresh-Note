//
//  PushNotificationRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 1/10/25.
//

import Combine
import Foundation

protocol PushNotificationRepository {
  /// 푸시 알림 권한 요청
//  func requestPermission() -> AnyPublisher<Bool, any Error>
  
  /// 지정된 날짜에 푸시 알림 예약
  /// - Parameters:
  /// - uuid: 제품의 고유 식별자
  /// - title: 알림 제목
  /// - body: 알림 내용
  /// - date: 알림이 발송될 날짜의 시간
  func scheduleNotification(
    noficationID: DocumentID,
    title: String,
    body: String,
    date: Date
  ) -> AnyPublisher<Void, any Error>
}
