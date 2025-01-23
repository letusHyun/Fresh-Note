//
//  DateTimeResponseDTO.swift
//  FreshNote
//
//  Created by SeokHyun on 11/28/24.
//

import Foundation

struct DateTimeResponseDTO: Decodable {
  let date: Int
  let hour: Int
  let minute: Int
}

extension DateTimeResponseDTO {
  func toDomain() -> DateTime {
    return DateTime(
      date: date,
      hour: hour,
      minute: minute
    )
  }
}
