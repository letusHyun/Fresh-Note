//
//  UserDefaultsPushNotiRestorationStateStorage.swift
//  FreshNote
//
//  Created by SeokHyun on 2/1/25.
//

import Combine
import Foundation

final class UserDefaultsPushNotiRestorationStateStorage: PushNotiRestorationStateStorage {
  private let userDefaults: UserDefaults
  private let backgroundQueue: DispatchQueue
  
  init(
    userDefaults: UserDefaults = .standard,
    backgroundQueue: DispatchQueue = .global(qos: .userInitiated)
  ) {
    self.userDefaults = userDefaults
    self.backgroundQueue = backgroundQueue
  }
  
  func save(restorationState: PushNotiRestorationState) -> AnyPublisher<Void, any Error> {
    return Deferred {
      Future { [weak self] promise in
        guard let self else { return }
        let uds = PushNotiRestorationStateUDS(shouldRestore: restorationState.shouldRestore)
        let encoder = JSONEncoder()
        
        guard let encodedData = try? encoder.encode(uds) else {
          return promise(.failure(UserDefaultsError.failedToEncode))
        }
        
        self.userDefaults.set(encodedData, forKey: UserDefaultsKey.pushNotiRestorationState.rawValue)
        promise(.success(()))
      }
    }
    .subscribe(on: self.backgroundQueue)
    .eraseToAnyPublisher()
  }
  
  func fetch() -> AnyPublisher<PushNotiRestorationState, any Error> {
    return Deferred {
      Future { [weak self] promise in
        guard let self else { return }
        
        guard let data = self.userDefaults.object(
          forKey: UserDefaultsKey.pushNotiRestorationState.rawValue
        ) as? Data else { return promise(.failure(UserDefaultsError.failedToConvertData)) }
        
        guard let uds = try? JSONDecoder().decode(PushNotiRestorationStateUDS.self, from: data) else {
          return promise(.failure(UserDefaultsError.failedToDecode))
        }
        return promise(.success(uds.toDomain()))
      }
    }
    .subscribe(on: self.backgroundQueue)
    .eraseToAnyPublisher()
  }
}
