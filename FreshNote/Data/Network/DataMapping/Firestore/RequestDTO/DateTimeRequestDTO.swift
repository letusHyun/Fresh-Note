//
//  DateTimeRequestDTO.swift
//  FreshNote
//
//  Created by SeokHyun on 11/28/24.
//

import Foundation

struct DateTimeRequestDTO: Encodable {
  let date: Int
  let hour: Int
  let minute: Int
}
