//
//  KeychainError.swift
//  FreshNote
//
//  Created by SeokHyun on 1/20/25.
//

import Foundation

enum KeychainError: Error {
  case convertToData
  case saveError
  case readError
  case deleteError
}
