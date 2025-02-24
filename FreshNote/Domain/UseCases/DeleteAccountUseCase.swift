//
//  DeleteAccountUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 2/2/25.
//

import Combine
import Foundation

protocol DeleteAccountUseCase {
  func execute() -> AnyPublisher<Void, any Error>
}

final class DefaultDeleteAccountUseCase: DeleteAccountUseCase {
  private let firebaseAuthRepository: any FirebaseAuthRepository
  private let firebaseDeletionRepository: any FirebaseDeletionRepository
  private let refreshTokenRepository: any RefreshTokenRepository
  private let pushNotiRestorationStateRepository: any PushNotiRestorationStateRepository
  private let pushNotificationRepository: any PushNotificationRepository
  private let deleteCacheRepository: any DeleteCacheRepository

  init(
    firebaseAuthRepository: any FirebaseAuthRepository,
    firebaseDeletionRepository: any FirebaseDeletionRepository,
    refreshTokenRepository: any RefreshTokenRepository,
    pushNotiRestorationStateRepository: any PushNotiRestorationStateRepository,
    pushNotificationRepository: any PushNotificationRepository,
    deleteCacheRepository: any DeleteCacheRepository
  ) {
    self.firebaseAuthRepository = firebaseAuthRepository
    self.firebaseDeletionRepository = firebaseDeletionRepository
    self.refreshTokenRepository = refreshTokenRepository
    self.pushNotiRestorationStateRepository = pushNotiRestorationStateRepository
    self.pushNotificationRepository = pushNotificationRepository
    self.deleteCacheRepository = deleteCacheRepository
  }
  
  func execute() -> AnyPublisher<Void, any Error> {
    // 1. firebase storage, firestore 데이터 삭제
    self.firebaseDeletionRepository
      .deleteUserWithAllData()
      .flatMap { [weak self] _ -> AnyPublisher<Void, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        // 2. firebase delete account common logic
        return self.firebaseAuthRepository
          .deleteAccount()
      }
      .flatMap { [weak self] _ -> AnyPublisher<[DocumentID], any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        
        // 3. caches delete
        return self.deleteCacheRepository
          .deleteCaches()
      }
      .flatMap { [weak self] productIDs -> AnyPublisher<Void, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        
        // 4. 푸시 알림 제거
        self.pushNotificationRepository.deleteNotificaion(notificationIDs: productIDs)
        
        // 5. refresh token revoke
        return self.refreshTokenRepository
          .revokeRefreshToken()
      }
      .flatMap { [weak self] _ -> AnyPublisher<Void, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        
        // 6. refresh token cache delete
        return self.refreshTokenRepository
          .deleteRefreshToken()
      }
      .flatMap { [weak self] _ -> AnyPublisher<Void, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        
        // 7. 푸시 알림 restore 여부 업데이트
        return self.pushNotiRestorationStateRepository
          .saveRestoreState(restorationState: PushNotiRestorationState(shouldRestore: false))
      }
      .eraseToAnyPublisher()
  }
}
