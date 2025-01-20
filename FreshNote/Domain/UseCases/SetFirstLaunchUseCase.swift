//
//  SetFirstLaunchUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 1/20/25.
//

import Combine
import Foundation

/// 앱 실행 시, refresh token의 초기 설정을 정의합니다.
protocol SetFirstLaunchUseCase {
  /// 최초 앱 시작인 경우 refresh token이 잔여한다면 token을 제거합니다.
  func execute() -> AnyPublisher<Void, any Error>
}

final class DefaultSetFirstLaunchUseCase: SetFirstLaunchUseCase {
  private let refreshTokenRepository: any RefreshTokenRepository
  private let firstLaunchRepository: any FirstLaunchRepository

  init(
    refreshTokenRepository: any RefreshTokenRepository,
    firstLaunchRepository: any FirstLaunchRepository
  ) {
    self.refreshTokenRepository = refreshTokenRepository
    self.firstLaunchRepository = firstLaunchRepository
  }
  
  func execute() -> AnyPublisher<Void, any Error> {
    // firstLaunchRepository를 사용해서,
      // value가 true이면 최초 앱 여부로 판단하고
        // refresh token을 삭제하는 코드 수행하기
      // value가 false이면 최초가 아니기 때문에 더이상 관여하지 않고 종료(refresh token이 있을수도, 없을 수도 있음)
    self.firstLaunchRepository
      .isFirstLaunched()
      .filter { $0 }
      .flatMap { [weak self] _ in
        guard let self else { return Empty<Void, any Error>().eraseToAnyPublisher() }
      
        return self.refreshTokenRepository
          .deleteRefreshToken()
      }
      .eraseToAnyPublisher()
  }
}
