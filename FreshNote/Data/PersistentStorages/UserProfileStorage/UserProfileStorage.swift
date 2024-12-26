//
//  UserProfileStorage.swift
//  FreshNote
//
//  Created by SeokHyun on 12/13/24.
//

import Combine
import Foundation

/// UserProfile은 User에 저장하기 때문에 firestore 또는 firebase storage를 거치지 않습니다.
protocol UserProfileStorage {
  func saveUserProfile(userProfile: UserProfile) -> AnyPublisher<UserProfile, any Error>
  func fetchUserProfile() -> AnyPublisher<UserProfile, any Error>
  func updateProfile(updatedUserProfile: UserProfileRequestDTO) -> AnyPublisher<UserProfile, any Error>
  func hasUserProfile() -> AnyPublisher<Bool, any Error>
}
