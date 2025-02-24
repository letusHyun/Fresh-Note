//
//  PushNotiRestorationStateUDS.swift
//  FreshNote
//
//  Created by SeokHyun on 2/1/25.
//

import Foundation

struct PushNotiRestorationStateUDS: Codable {
  let shouldRestore: Bool
}

// MARK: - Mapping To Domain
extension PushNotiRestorationStateUDS {
  func toDomain() -> PushNotiRestorationState {
    return PushNotiRestorationState(shouldRestore: self.shouldRestore)
  }
}
