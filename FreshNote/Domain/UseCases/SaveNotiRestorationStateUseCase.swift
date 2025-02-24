//
//  SaveNotiRestorationStateUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 2/22/25.
//

import Combine
import Foundation

protocol SaveNotiRestorationStateUseCase {
  func execute(shouldRestore: Bool) -> AnyPublisher<Void, any Error>
}

final class DefaultSaveNotiRestorationStateUseCase: SaveNotiRestorationStateUseCase {
  private let pushNotiRestorationStateRepository: any PushNotiRestorationStateRepository
  
  init(
    pushNotiRestorationStateRepository: any PushNotiRestorationStateRepository
  ) {
    self.pushNotiRestorationStateRepository = pushNotiRestorationStateRepository
  }
  
  func execute(shouldRestore: Bool) -> AnyPublisher<Void, any Error> {
    return self.pushNotiRestorationStateRepository
      .saveRestoreState(restorationState: PushNotiRestorationState(shouldRestore: shouldRestore))
  }
}
