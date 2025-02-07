//
//  ConnectionError.swift
//  FreshNote
//
//  Created by SeokHyun on 2/5/25.
//

import Foundation

protocol ConnectionError: Error {
  /// 재로그인을 요구하는 에러
  var isRecentLoginRequiringError: Bool { get }
}

extension Error {
  var isRecentLoginRequiringError: Bool {
    guard let error = self as? ConnectionError, error.isRecentLoginRequiringError else {
      return false
    }
    return true
  }
}
