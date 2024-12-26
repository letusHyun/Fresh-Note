//
//  SignInStateStorage.swift
//  FreshNote
//
//  Created by SeokHyun on 12/15/24.
//

import Combine
import Foundation

protocol SignInStateStorage {
  /// signInState를 읽어옵니다.
  /// 저장한 적이 없으면 false를 반환합니다.
  func fetchSignInState() -> AnyPublisher<Bool, any Error>
  func saveSignInState() -> AnyPublisher<Void, any Error>
  func updateSignInState(updateToValue: Bool) -> AnyPublisher<Void, any Error>
}
