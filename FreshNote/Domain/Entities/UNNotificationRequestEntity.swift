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
  let title: String
  let body: String
  /// 알림 발송날짜
  let date: Date
  
  init(noficationID: DocumentID, productName: String, remainingDay: Int, date: Date) {
    self.noficationID = noficationID.didString
    self.title = "유통기한 알림"
    self.body = "\(productName)의 유통기한이 \(remainingDay)일 남았습니다."
    self.date = date
  }
}
