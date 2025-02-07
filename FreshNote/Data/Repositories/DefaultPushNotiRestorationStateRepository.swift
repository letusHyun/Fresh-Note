//
//  DefaultPushNotiRestorationStateRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 2/1/25.
//

import Combine
import Foundation

final class DefaultPushNotiRestorationStateRepository: PushNotiRestorationStateRepository {
  private let restoreStateStorage: any PushNotiRestorationStateStorage
  
  init(restoreStateStorage: any PushNotiRestorationStateStorage) {
    self.restoreStateStorage = restoreStateStorage
  }
  
  func saveRestoreState(restorationState: PushNotiRestorationState) -> AnyPublisher<Void, any Error> {
    self.restoreStateStorage.save(restorationState: restorationState)
  }
  
  func fetchRestoreState() -> AnyPublisher<PushNotiRestorationState, any Error> {
    self.restoreStateStorage.fetch()
  }
}
