//
//  FirebaseAuthRepositoryError+ConnectionError.swift
//  FreshNote
//
//  Created by SeokHyun on 2/5/25.
//

import Foundation

extension FirebaseAuthRepositoryError: ConnectionError {
  var isRecentLoginRequiringError: Bool {
    guard case FirebaseAuthRepositoryError.requireRecentLogin = self else { return false }
    return true
  }
}
