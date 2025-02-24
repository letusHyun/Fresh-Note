//
//  DateTimeRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 10/26/24.
//

import Foundation
import Combine

protocol DateTimeRepository {
  func fetchDateTime() -> AnyPublisher<DateTime, any Error>
  func saveDateTime(dateTime: DateTime) -> AnyPublisher<Void, any Error>
  /// firestore에 dateTime이 저장되었는지 판별하는 메소드입니다.
  ///  dateTime이 존재한다면, cache에 저장합니다.
  ///
  /// onboarding화면의 스킵 여부에 사용됩니다.
  func isSavedDateTime() -> AnyPublisher<Bool, any Error>
  func updateDateTime(dateTime: DateTime) -> AnyPublisher<Void, any Error>
  func deleteCachedDateTime() -> AnyPublisher<Void, any Error>
}
