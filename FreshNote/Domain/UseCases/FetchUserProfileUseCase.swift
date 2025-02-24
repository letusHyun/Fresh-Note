//
//  FetchUserProfileUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 12/13/24.
//

import Combine
import Foundation

protocol FetchUserProfileUseCase {
  func execute() -> AnyPublisher<UserProfile, any Error>
}

final class DefaultFetchUserProfileUseCase: FetchUserProfileUseCase {
  private let userProfileRepository: any UserProfileRepository
  
  init(userProfileRepository: any UserProfileRepository) {
    self.userProfileRepository = userProfileRepository
  }
  
  func execute() -> AnyPublisher<UserProfile, any Error> {
    self.userProfileRepository.fetchUserProfile()
  }
}
