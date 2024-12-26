//
//  UserDefaultsSignInStateStorage.swift
//  FreshNote
//
//  Created by SeokHyun on 12/15/24.
//

import Combine
import Foundation

final class UserDefaultsSignInStateStorage {
  private let userDefaults: UserDefaults
  private let backgroundQueue: DispatchQueue
  
  init(
    userDefaults: UserDefaults = UserDefaults.standard,
    backgroundQueue: DispatchQueue = .global(qos: .userInitiated)
  ) {
    self.userDefaults = userDefaults
    self.backgroundQueue = backgroundQueue
  }
}

extension UserDefaultsSignInStateStorage: SignInStateStorage {
  func fetchSignInState() -> AnyPublisher<Bool, any Error> {
    return Just(())
      .receive(on: self.backgroundQueue)
      .flatMap { [weak self] _ in
        guard let self else { return Empty<Bool, any Error>().eraseToAnyPublisher() }
        
        // UserDefaults에 값이 존재하지 않으면 false 반환
        guard let data = self.userDefaults.object(forKey: UserDefaultsKey.signInState.rawValue) as? Data else {
          return Just(false)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        }
        
        guard let signInState = try? JSONDecoder().decode(SignInStateUDS.self, from: data) else {
          return Fail<Bool, any Error>(error: UserDefaultsError.failedToDecode).eraseToAnyPublisher()
        }
        
        // 로그인 상태 반환
        return Just(signInState.isSignedIn)
          .setFailureType(to: Error.self)
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
  
  func saveSignInState() -> AnyPublisher<Void, any Error> {
    return Just(())
      .receive(on: self.backgroundQueue)
      .flatMap { [weak self] _ in
        guard let self else { return Empty<Void, any Error>().eraseToAnyPublisher() }
        let signInStateUDS = SignInStateUDS(isSignedIn: true)
        let encoder = JSONEncoder()
        
        guard let encodedData = try? encoder.encode(signInStateUDS) else {
          return Fail<Void, any Error>(error: UserDefaultsError.failedToEncode).eraseToAnyPublisher()
        }
        
        self.userDefaults.set(encodedData, forKey: UserDefaultsKey.signInState.rawValue)
        
        return Just(())
          .setFailureType(to: (any Error).self)
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
  
  func updateSignInState(updateToValue: Bool) -> AnyPublisher<Void, any Error> {
    return Just(())
      .receive(on: self.backgroundQueue)
      .flatMap { [weak self] _  -> AnyPublisher<Void, any Error> in
        guard let self else { return Empty().eraseToAnyPublisher() }
        
        guard let data = self.userDefaults.object(forKey: UserDefaultsKey.signInState.rawValue) as? Data else {
          return Fail(error: UserDefaultsError.failedToConvertData).eraseToAnyPublisher()
        }
        
        guard var currentState = try? JSONDecoder().decode(SignInStateUDS.self, from: data) else {
          return Fail(error: UserDefaultsError.failedToDecode).eraseToAnyPublisher()
        }
        
        currentState.isSignedIn = updateToValue
        
        guard let encodedState = try? JSONEncoder().encode(currentState) else {
          return Fail(error: UserDefaultsError.failedToEncode).eraseToAnyPublisher()
        }
        
        self.userDefaults.set(encodedState, forKey: UserDefaultsKey.signInState.rawValue)
        
        return Just(())
          .setFailureType(to: Error.self)
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
}
