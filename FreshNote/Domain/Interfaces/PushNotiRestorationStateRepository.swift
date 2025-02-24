//
//  PushNotiRestorationStateRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 2/2/25.
//

import Combine
import Foundation

protocol PushNotiRestorationStateRepository {
  func saveRestoreState(restorationState: PushNotiRestorationState) -> AnyPublisher<Void, any Error>
  func fetchRestoreState() -> AnyPublisher<PushNotiRestorationState, any Error>
}
