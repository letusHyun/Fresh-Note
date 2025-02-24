//
//  PushNotiRestorationStateStorage.swift
//  FreshNote
//
//  Created by SeokHyun on 2/1/25.
//

import Combine
import Foundation

protocol PushNotiRestorationStateStorage {
  func save(restorationState: PushNotiRestorationState) -> AnyPublisher<Void, any Error>
  func fetch() -> AnyPublisher<PushNotiRestorationState, any Error>
}
