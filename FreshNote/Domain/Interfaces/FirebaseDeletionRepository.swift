//
//  FirebaseDeletionRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 2/3/25.
//

import Combine
import Foundation

protocol FirebaseDeletionRepository {
  func deleteUserWithAllData() -> AnyPublisher<Void, any Error>
}
