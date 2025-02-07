//
//  DateTimeStorage.swift
//  FreshNote
//
//  Created by SeokHyun on 1/11/25.
//

import Combine
import Foundation

protocol DateTimeStorage {
  func saveDateTime(dateTime: DateTime) -> AnyPublisher<DateTime, any Error>
  func updateDateTime(dateTime: DateTime) -> AnyPublisher<DateTime, any Error>
  func fetchDateTime() -> AnyPublisher<DateTime, any Error>
  func deleteDateTime() -> AnyPublisher<Void, any Error>
  func deleteAll() -> AnyPublisher<Void, any Error>
}
