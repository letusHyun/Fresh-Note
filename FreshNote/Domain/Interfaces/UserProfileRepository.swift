//
//  UserProfileRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 12/13/24.
//

import Combine
import Foundation

/// 사용자의 프로필을 담당하는 Repository입니다.
protocol UserProfileRepository {
  func saveUserProfile(userProfile: UserProfile) -> AnyPublisher<UserProfile, any Error>
  func fetchUserProfile() -> AnyPublisher<UserProfile, any Error>
  func updateUserProfile(updatedUserProfile: UserProfile) -> AnyPublisher<UserProfile, any Error>
}
