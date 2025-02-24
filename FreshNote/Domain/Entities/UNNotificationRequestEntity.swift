//
//  UNNotificationRequestEntity.swift
//  FreshNote
//
//  Created by SeokHyun on 1/14/25.
//

import Foundation

/// 푸시 알림을 생성할 때 사용됩니다.
struct UNNotificationRequestEntity {
  let noficationID: String
  /// 푸시 알림 title
  let title: String
  /// 알림 발송날짜
  let date: Date
  /// 푸시 알림 body
  let body: String
  
  init(noficationID: DocumentID, productName: String, remainingDay: Int, notificationDate: Date) {
    self.noficationID = noficationID.didString
    self.title = NotificationHelper.title
    self.date = notificationDate
    
    let body = NotificationHelper.makeBody(
      productName: productName,
      remainingDay: remainingDay
    )
    self.body = body
  }
}
