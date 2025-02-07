//
//  KeychainRefreshTokenStorage.swift
//  FreshNote
//
//  Created by SeokHyun on 1/20/25.
//

import Combine
import Foundation

enum KeychainRefreshTokenStorageError: Error {
  case referenceError
  case noData
  case decodingError
}

final class KeychainRefreshTokenStorage: RefreshTokenStorage {
  private let backgroundQueue: DispatchQueue
  
  private var serviceName: String {
    Bundle.main.bundleIdentifier ?? ""
  }
  
  private var accountName: String {
    KeychainKey.refreshToken.rawValue
  }
  
  
  init(backgroundQueue: DispatchQueue = .global(qos: .userInitiated)) {
    self.backgroundQueue = backgroundQueue
  }
  
  func saveRefreshToken(_ refreshToken: String) -> AnyPublisher<Void, any Error> {
    Deferred {
      Future { [weak self] promise in
        guard let self else { return promise(.failure(KeychainRefreshTokenStorageError.referenceError)) }
        guard let tokenData = refreshToken.data(using: .utf8) else {
          return promise(.failure(KeychainError.convertToData))
        }
        
        let query = [
          kSecValueData: tokenData,
          kSecClass: kSecClassGenericPassword,
          kSecAttrService: self.serviceName,
          kSecAttrAccount: self.accountName
        ] as [CFString: Any]
        
        // 안정성 보장을 위해 delete 이후 save
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
          return promise(.failure(KeychainError.saveError))
        }
        return promise(.success(()))
      }
      .eraseToAnyPublisher()
    }
    .subscribe(on: self.backgroundQueue)
    .eraseToAnyPublisher()
    
  }
  
  func fetchRefreshToken() -> AnyPublisher<String, any Error> {
    return Deferred {
      Future { [weak self] promise in
        guard let self else { return promise(.failure(KeychainRefreshTokenStorageError.referenceError)) }
        
        let query: [String: Any] = [
          kSecClass as String: kSecClassGenericPassword,
          kSecAttrService as String: self.serviceName,
          kSecAttrAccount as String: self.accountName,
          kSecReturnData as String: true,
          kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
          if status == errSecItemNotFound {
            return promise(.failure(KeychainRefreshTokenStorageError.noData))
          }
          return promise(.failure(KeychainError.readError))
        }
        
        guard let tokenData = result as? Data else {
          return promise(.failure(KeychainRefreshTokenStorageError.noData))
        }
        
        guard let token = String(data: tokenData, encoding: .utf8) else {
          return promise(.failure(KeychainRefreshTokenStorageError.decodingError))
        }
        
        return promise(.success(token))
      }
      .eraseToAnyPublisher()
    }
    .subscribe(on: self.backgroundQueue)
    .eraseToAnyPublisher()
  }
  
  func deleteRefreshToken() -> AnyPublisher<Void, any Error> {
    return Deferred {
      Future { [weak self] promise in
        guard let self else { return promise(.failure(KeychainRefreshTokenStorageError.referenceError)) }
        
        let query: [String: Any] = [
          kSecClass as String: kSecClassGenericPassword,
          kSecAttrAccount as String: self.accountName,
          kSecAttrService as String: self.serviceName
        ]
        
        SecItemDelete(query as CFDictionary)
        
        return promise(.success(()))
      }
      .eraseToAnyPublisher()
    }
    .subscribe(on: self.backgroundQueue)
    .eraseToAnyPublisher()
  }
}
