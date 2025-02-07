//
//  UpdateUserProfileUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 12/18/24.
//

import Combine
import Foundation

protocol UpdateUserProfileUseCase {
  func execute(
    userProfile: UserProfile,
    newImageData: Data?
  ) -> AnyPublisher<UserProfile, any Error>
}

final class DefaultUpdateUserProfileUseCase: UpdateUserProfileUseCase {
  private let userProfileRepository: any UserProfileRepository
  private let imageRepository: any ImageRepository
  
  init(
    userProfileRepository: any UserProfileRepository,
    imageRepository: any ImageRepository
  ) {
    self.userProfileRepository = userProfileRepository
    self.imageRepository = imageRepository
  }
  
  func execute(
    userProfile: UserProfile,
    newImageData: Data?
  ) -> AnyPublisher<UserProfile, any Error> {
    // 새 이미지가 없는 경우
      // return userProfile 업데이트
    guard let newImageData = newImageData else {
      return self.userProfileRepository
        .updateUserProfile(updatedUserProfile: userProfile)
    }
    
    /// 새 이미지가 있는 경우
    
      // 기존 이미지가 없는 경우
        // 이미지 저장 후, userProfile 업데이트
    let newFileName = UUID().uuidString
    
    guard let originalImageURL = userProfile.imageURL else {
      return self.imageRepository
        .saveImage(with: newImageData, fileName: newFileName)
        .flatMap { [weak self] url in
          guard let self else {
            return Fail<UserProfile, any Error>(error: CommonError.referenceError).eraseToAnyPublisher()
          }
          
          let updatedUserProfile = UserProfile(name: userProfile.name, imageURL: url)
          
          return self.userProfileRepository
            .updateUserProfile(updatedUserProfile: updatedUserProfile)
        }
        .eraseToAnyPublisher()
    }
    
      // 기존 이미지가 있는 경우
        // 기존 이미지 삭제 -> 새 이미지 저장 -> userProfile 업데이트
    return self.imageRepository.deleteImage(with: originalImageURL)
      .flatMap { [weak self] in
        guard let self else {
          return Fail<UserProfile, any Error>(error: CommonError.referenceError).eraseToAnyPublisher()
        }
        
        return self.imageRepository
          .saveImage(with: newImageData, fileName: newFileName)
          .flatMap { url in
            let updatedUserProfile = UserProfile(name: userProfile.name, imageURL: url)
            
            return self.userProfileRepository
              .updateUserProfile(updatedUserProfile: updatedUserProfile)
          }
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
}
