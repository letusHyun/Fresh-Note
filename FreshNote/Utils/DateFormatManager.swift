//
//  DateFormatManager.swift
//  FreshNote
//
//  Created by SeokHyun on 12/4/24.
//

import Foundation

struct DateFormatManager {
  private let dateFormatter: DateFormatter
  
  init(dateFormat: String = "yy.MM.dd") {
    let formatter = DateFormatter()
    formatter.dateFormat = dateFormat
    formatter.timeZone = TimeZone.current
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "ko_KR")
    
    self.dateFormatter = formatter
  }
  
  
  func makeCurrentDate() -> Date {
    Date()
  }
  
  func string(from date: Date) -> String {
    return dateFormatter.string(from: date)
  }
  
  func date(from string: String) -> Date? {
    return dateFormatter.date(from: string)
  }
}
