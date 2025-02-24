//
//  CheckInitialStateUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 1/31/25.
//

import Combine
import Foundation

protocol CheckInitialStateUseCase {
  /// 최초 앱 실행 여부를 확인합니다.
  func checkFirstLaunchState() -> AnyPublisher<Bool, any Error>
  /// refresh token이 존재하는지 확인합니다.
  func checkRefreshTokenState() -> AnyPublisher<Bool, any Error>
  /// 로그아웃 상태인지 확인합니다.
  func checkSignOutState() -> AnyPublisher<Bool, Never>
  /// 날짜 설정여부를 확인합니다.
  func checkDateTimeSetting() -> AnyPublisher<Bool, any Error>
}

final class DefaultCheckInitialStateUseCase: CheckInitialStateUseCase {
  private let firstLaunchRepository: any FirstLaunchRepository
  private let refreshTokenRepository: any RefreshTokenRepository
  private let authRepository: any FirebaseAuthRepository
  private let dateTimeRepository: any DateTimeRepository
  
  init(
    firstLaunchRepository: any FirstLaunchRepository,
    refreshTokenRepository: any RefreshTokenRepository,
    authRepository: any FirebaseAuthRepository,
    dateTimeRepository: any DateTimeRepository
  ) {
    self.firstLaunchRepository = firstLaunchRepository
    self.refreshTokenRepository = refreshTokenRepository
    self.authRepository = authRepository
    self.dateTimeRepository = dateTimeRepository
  }
  
  func checkRefreshTokenState() -> AnyPublisher<Bool, any Error> {
    self.refreshTokenRepository.isSavedRefreshToken()
  }
  
  func checkSignOutState() -> AnyPublisher<Bool, Never> {
    self.authRepository.checkSignOutState()
  }
  
  func checkDateTimeSetting() -> AnyPublisher<Bool, any Error> {
    self.dateTimeRepository.isSavedDateTime()
  }
  
  func checkFirstLaunchState() -> AnyPublisher<Bool, any Error> {
    self.firstLaunchRepository
      .isFirstLaunched()
  }
}
