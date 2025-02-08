//
//  CheckInitialStateUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 1/31/25.
//

import Combine
import Foundation

protocol CheckInitialStateUseCase {
  /// refresh token이 존재하는지 확인합니다.
  func checkRefreshTokenState() -> AnyPublisher<Bool, any Error>
  /// 로그아웃 상태인지 확인합니다.
  func checkSignOutState() -> AnyPublisher<Bool, Never>
  /// 날짜 설정여부를 확인합니다.
  func checkDateTimeSetting() -> AnyPublisher<Bool, any Error>
  /// 로그인 여부에 따라 restorationState값을 저장합니다.
  func saveInitRestorationState() -> AnyPublisher<Void, any Error>
}

final class DefaultCheckInitialStateUseCase: CheckInitialStateUseCase {
  private let firstLaunchRepository: any FirstLaunchRepository
  private let refreshTokenRepository: any RefreshTokenRepository
  private let authRepository: any FirebaseAuthRepository
  private let dateTimeRepository: any DateTimeRepository
  private let pushNotiRestorationStateRepository: any PushNotiRestorationStateRepository
  
  init(
    firstLaunchRepository: any FirstLaunchRepository,
    refreshTokenRepository: any RefreshTokenRepository,
    authRepository: any FirebaseAuthRepository,
    dateTimeRepository: any DateTimeRepository,
    pushNotiRestorationStateRepository: any PushNotiRestorationStateRepository
  ) {
    self.firstLaunchRepository = firstLaunchRepository
    self.refreshTokenRepository = refreshTokenRepository
    self.authRepository = authRepository
    self.dateTimeRepository = dateTimeRepository
    self.pushNotiRestorationStateRepository = pushNotiRestorationStateRepository
  }
  
  func checkRefreshTokenState() -> AnyPublisher<Bool, any Error> {
    self.refreshTokenRepository.isSavedRefreshToken()
  }
  
  func checkSignOutState() -> AnyPublisher<Bool, Never> {
    self.authRepository.checkSignOutState()
  }
  
  func checkDateTimeSetting() -> AnyPublisher<Bool, any Error> {
    self.dateTimeRepository.isSavedDateTime()
      .flatMap { [weak self] isSavedDateTime -> AnyPublisher<Bool, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        
        // dateTime값이 존재하는 경우에만
        if isSavedDateTime {
          return self.pushNotiRestorationStateRepository // shouldRestore true 저장
            .saveRestoreState(restorationState: PushNotiRestorationState(shouldRestore: true))
            .map { isSavedDateTime }
            .eraseToAnyPublisher()
        }
        
        return Just(isSavedDateTime)
          .setFailureType(to: Error.self)
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
  
  func saveInitRestorationState() -> AnyPublisher<Void, any Error> {
    return self.firstLaunchRepository
      .isFirstLaunched()
      .flatMap { [weak self] isFirstLaunched -> AnyPublisher<Void, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        
        if isFirstLaunched { // 최초 앱 실행한 경우
          return self.authRepository.checkSignOutState()
            .flatMap { isSignedOut in
              if isSignedOut { // 로그아웃 되어있는 경우
                // restorationState false 저장
                return self.pushNotiRestorationStateRepository
                  .saveRestoreState(restorationState: PushNotiRestorationState(shouldRestore: false))
              } else { // 로그인 되어있는 경우
                // restorationState true 저장
                return self.pushNotiRestorationStateRepository
                  .saveRestoreState(restorationState: PushNotiRestorationState(shouldRestore: true))
              }
            }
            .eraseToAnyPublisher()
        } else { // 최초 앱 실행이 아닌 경우
          return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        }
      }
      .eraseToAnyPublisher()
  }
}
