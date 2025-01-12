//
//  DateTimeEntity+Mapping.swift
//  FreshNote
//
//  Created by SeokHyun on 1/11/25.
//

import CoreData
import Foundation

extension DateTimeEntity {
  convenience init(dateTime: DateTime, insertInto context: NSManagedObjectContext) {
    self.init(context: context)
    self.date = Int16(dateTime.date)
    self.hour = Int16(dateTime.hour)
    self.minute = Int16(dateTime.minute)
  }
}

extension DateTimeEntity {
  func toDomain() -> DateTime {
    return DateTime(
      date: Int(self.date),
      hour: Int(self.hour),
      minute: Int(self.minute)
    )
  }
}
