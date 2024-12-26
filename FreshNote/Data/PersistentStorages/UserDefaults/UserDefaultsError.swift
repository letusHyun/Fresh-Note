//
//  UserDefaultsError.swift
//  FreshNote
//
//  Created by SeokHyun on 12/15/24.
//

import Foundation

enum UserDefaultsError: Error {
  case fetchError
  case saveError
  case failedToDecode
  case failedToEncode
  case failedToConvertData
}
