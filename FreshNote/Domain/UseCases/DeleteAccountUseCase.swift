//
//  DeleteAccountUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 2/2/25.
//

import Combine
import Foundation

protocol DeleteAccountUseCase {
  func deleteAccount() -> AnyPublisher<Void, any Error>
  // 회원탈퇴를 다시 수행하는 경우 호출합니다.
  func redeleteAccount() -> AnyPublisher<Void, any Error>
}

final class DefaultDeleteAccountUseCase: DeleteAccountUseCase {
  private let firebaseAuthRepository: any FirebaseAuthRepository
  private let firebaseDeletionRepository: any FirebaseDeletionRepository
  private let refreshTokenRepository: any RefreshTokenRepository
  private let pushNotiRestorationStateRepository: any PushNotiRestorationStateRepository
  private let deleteCacheRepository: any DeleteCacheRepository

  init(
    firebaseAuthRepository: any FirebaseAuthRepository,
    firebaseDeletionRepository: any FirebaseDeletionRepository,
    refreshTokenRepository: any RefreshTokenRepository,
    pushNotiRestorationStateRepository: any PushNotiRestorationStateRepository,
    deleteCacheRepository: any DeleteCacheRepository
  ) {
    self.firebaseAuthRepository = firebaseAuthRepository
    self.firebaseDeletionRepository = firebaseDeletionRepository
    self.refreshTokenRepository = refreshTokenRepository
    self.pushNotiRestorationStateRepository = pushNotiRestorationStateRepository
    self.deleteCacheRepository = deleteCacheRepository
  }
  
  func deleteAccount() -> AnyPublisher<Void, any Error> {
    // 1. firebase storage, firestore 데이터 삭제
    self.firebaseDeletionRepository
      .deleteUserWithAllData()
      .flatMap { [weak self] _ -> AnyPublisher<Void, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        // 2. firebase delete account common logic
        return self.deleteAccountCommonLogic()
      }
      .eraseToAnyPublisher()
  }
  
  func redeleteAccount() -> AnyPublisher<Void, any Error> {
    return self.deleteAccountCommonLogic()
  }
  
  // MARK: - Private
  private func deleteAccountCommonLogic() -> AnyPublisher<Void, any Error> {
    // firebase delete account
    return self.firebaseAuthRepository
      .deleteAccount()
      .flatMap { [weak self] _ -> AnyPublisher<Void, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        
        // caches delete
        return self.deleteCacheRepository
          .deleteCaches()
      }
      .flatMap { [weak self] _ -> AnyPublisher<Void, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        
        // refresh token revoke
        return self.refreshTokenRepository
          .revokeRefreshToken()
      }
      .flatMap { [weak self] _ -> AnyPublisher<Void, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        
        // refresh token cache delete
        return self.refreshTokenRepository
          .deleteRefreshToken()
      }
      .flatMap { [weak self] _ -> AnyPublisher<Void, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        
        // 푸시 알림 restore 여부 업데이트
        return self.pushNotiRestorationStateRepository
          .saveRestoreState(restorationState: PushNotiRestorationState(shouldRestore: false))
      }
      .eraseToAnyPublisher()
  }
}
