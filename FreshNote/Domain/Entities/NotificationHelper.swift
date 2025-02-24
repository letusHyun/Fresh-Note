//
//  NotificationHelper.swift
//  FreshNote
//
//  Created by SeokHyun on 1/15/25.
//

import Foundation

/// 로컬 푸시 알림 문구 생성을 도와주는 객체입니다.
struct NotificationHelper {
  private static let pattern: String = "%@의 유통기한이 %d일 남았습니다."
  
  static var title: String {
    "Fresh Note"
  }
  
  /// 로컬 푸시 알림의 body를 생성합니다.
  static func makeBody(productName: String, remainingDay: Int) -> String {
    return String(
      format: pattern,
      productName, remainingDay
    )
  }
  
  /// 로컬 푸시 알림 body로부터 제품의 title과 remainingDay를 추출합니다.
  static func extractTitleAndDay(from text: String) -> (productName: String, remainingDay: Int)? {
    let pattern = "(.+)의 유통기한이 (\\d+)일 남았습니다."
    
    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
      return nil
    }
    
    guard
      let productNameRange = Range(match.range(at: 1), in: text),
      let dayRange = Range(match.range(at: 2), in: text),
      let remainingDay = Int(text[dayRange])
    else { return nil }
    
    let productName = String(text[productNameRange])
    
    return (productName: productName, remainingDay: remainingDay)
  }
}
