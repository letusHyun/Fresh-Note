//
//  KeychainPushNotiRestorationStateStorage.swift
//  FreshNote
//
//  Created by SeokHyun on 2/8/25.
//

import Combine
import Foundation

enum KeychainPushNotiRestorationStateStorageError: Error {
  case noData
  case decodingError
  case referenceError
}

final class KeychainPushNotiRestorationStateStorage {
  // MARK: - Properties
  private var serviceName: String {
    Bundle.main.bundleIdentifier ?? ""
  }
  
  private var accountName: String {
    KeychainKey.refreshToken.rawValue
  }
  
  private let backgroundQueue: DispatchQueue
  
  // MARK: - LifeCycle
  init(backgroundQueue: DispatchQueue = .global(qos: .userInitiated)) {
    self.backgroundQueue = backgroundQueue
  }
}

// MARK: - PushNotiRestorationStateStorage
extension KeychainPushNotiRestorationStateStorage: PushNotiRestorationStateStorage {
  func save(restorationState: PushNotiRestorationState) -> AnyPublisher<Void, any Error> {
    Deferred {
      Future { [weak self] promise in
        guard let self else { return promise(.failure(KeychainRefreshTokenStorageError.referenceError)) }
        let data = Data([restorationState.shouldRestore ? 1 : 0])
        let query = [
          kSecValueData: data,
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
      .subscribe(on: self.backgroundQueue)
      .eraseToAnyPublisher()
    }
    .eraseToAnyPublisher()
  }
  
  func fetch() -> AnyPublisher<PushNotiRestorationState, any Error> {
    Deferred {
      Future { [weak self] promise in
        guard let self else {
          return promise(.failure(KeychainPushNotiRestorationStateStorageError.referenceError))
        }
        
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
            return promise(.failure(KeychainPushNotiRestorationStateStorageError.noData))
          }
          return promise(.failure(KeychainError.readError))
        }
        
        guard let data = result as? Data else {
          return promise(.failure(KeychainPushNotiRestorationStateStorageError.noData))
        }
        
        guard let firstByte = data.first else {
          return promise(.failure(KeychainPushNotiRestorationStateStorageError.noData))
        }
        
        let state = PushNotiRestorationState(shouldRestore: firstByte == 1)
        return promise(.success(state))
      }
      .eraseToAnyPublisher()
    }
    .receive(on: self.backgroundQueue)
    .eraseToAnyPublisher()
  }
}
