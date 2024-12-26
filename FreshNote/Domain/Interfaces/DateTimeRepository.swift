//
//  DateTimeRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 10/26/24.
//

import Foundation
import Combine

protocol DateTimeRepository {
  func fetchDateTime() -> AnyPublisher<Alarm, any Error>
  func saveDateTime(date: Int, hour: Int, minute: Int) -> AnyPublisher<Void, any Error>
  func isSavedDateTime() -> AnyPublisher<Bool, any Error>
}
