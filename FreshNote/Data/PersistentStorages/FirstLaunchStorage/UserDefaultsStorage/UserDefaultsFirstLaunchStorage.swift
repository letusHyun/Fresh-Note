//
//  UserDefaultsFirstLaunchStorage.swift
//  FreshNote
//
//  Created by SeokHyun on 1/20/25.
//

import Combine
import Foundation

final class UserDefaultsFirstLaunchStorage: FirstLaunchStorage {
  private let userDefaults: UserDefaults
  
  private let backgroundQueue: DispatchQueue
  
  init(
    userDefaults: UserDefaults = .standard,
    backgroundQueue: DispatchQueue = .global(qos: .userInitiated)
  ) {
    self.userDefaults = userDefaults
    self.backgroundQueue = backgroundQueue
  }
  
  func saveFirstLaunchState() -> AnyPublisher<Void, any Error> {
    Deferred {
      Future { [weak self] promise in
        guard let self else { return }
        let firstLaunchStateUDS = FirstLaunchStateUDS(isFirstLaunched: true)
        let encoder = JSONEncoder()
        
        guard let encodedData = try? encoder.encode(firstLaunchStateUDS) else {
          return promise(.failure(UserDefaultsError.failedToEncode))
        }
        
        self.userDefaults.set(encodedData, forKey: UserDefaultsKey.firstLaunchState.rawValue)
        promise(.success(()))
      }
    }
    .subscribe(on: self.backgroundQueue)
    .eraseToAnyPublisher()
  }
  
  func fetchFirstLaunchState() -> AnyPublisher<Bool, any Error> {
    return Deferred {
      Future { [weak self] promise in
        guard let self else { return }
        
        // userDefaults에 값이 존재하지 않으면 false 반환
        guard let data = self.userDefaults.object(
          forKey: UserDefaultsKey.firstLaunchState.rawValue
        ) as? Data else {
          return promise(.success(false))
        }
        
        guard let firstLaunchStateUDS = try? JSONDecoder().decode(
          FirstLaunchStateUDS.self, from: data
        ) else {
          return promise(.failure(UserDefaultsError.failedToDecode))
        }
        
        return promise(.success(firstLaunchStateUDS.isFirstLaunched))
      }
    }
    .subscribe(on: self.backgroundQueue)
    .eraseToAnyPublisher()
  }
}
