//
//  SignInStateRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 12/15/24.
//

import Combine
import Foundation

/// 유저의 로그인 상태를 관리합니다.
protocol SignInStateRepository {
  /// 로그인 상태라면 true, 로그인 상태가 아니라면 false를 반환합니다.
  /// storage, firebase token, apple credential을 통해 로그인 여부를 판별합니다.
  /// 판별 도중 실패한다면, storage의 값도 업데이트합니다.
  func checkSignIn() -> AnyPublisher<Bool, any Error>
  func updateSignInState(updateToValue: Bool) -> AnyPublisher<Void, any Error>
  func saveSignInState() -> AnyPublisher<Void, any Error>
}
