//
//  FirebaseAuthRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 12/13/24.
//

import Combine
import Foundation
import FirebaseAuth

protocol FirebaseAuthRepository {
  // 로그인을 수행합니다.
  func signIn(
    idToken: String,
    nonce: String,
    fullName: PersonNameComponents?
  ) -> AnyPublisher<Void, any Error>
  
  func signOut() -> AnyPublisher<Void, any Error>
  
  func checkSignOutState() -> AnyPublisher<Bool, Never>
  
  func deleteAccount() -> AnyPublisher<Void, any Error>
  
  /// 재인증을 수행합니다.
  ///
  /// 회원탈퇴 시 재인증을 해야합니다.
  func reauthenticate(
    idToken: String,
    nonce: String,
    fullName:  PersonNameComponents?
  ) -> AnyPublisher<Void, any Error>
}
