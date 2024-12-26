//
//  SaveUserProfileUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 12/13/24.
//

import Combine
import Foundation

protocol SaveUserProfileUseCase {
  func execute(requestValue: SaveUserProfileUseCaseRequestValue) -> AnyPublisher<UserProfile, any Error>
}

final class DefaultSaveUserProfileUseCase: SaveUserProfileUseCase {
  private let userProfileRepository: any UserProfileRepository
  private let imageRepository: any ImageRepository
  
  init(
    userProfileRepository: any UserProfileRepository,
    imageRepository: any ImageRepository
  ) {
    self.userProfileRepository = userProfileRepository
    self.imageRepository = imageRepository
  }
  
  func execute(requestValue: SaveUserProfileUseCaseRequestValue) -> AnyPublisher<UserProfile, any Error> {
    let fileName = UUID().uuidString
    if let imageData = requestValue.imageData {
      return self.imageRepository
        .saveImage(with: imageData, fileName: fileName)
        .flatMap { [weak self] url in
          guard let self else { return Empty<UserProfile, any Error>().eraseToAnyPublisher() }
          
          let userProfile = UserProfile(name: requestValue.name, imageURL: url)
          return self.userProfileRepository.saveUserProfile(userProfile: userProfile)
        }
        .eraseToAnyPublisher()
    }
    
    return self.userProfileRepository
      .saveUserProfile(userProfile: UserProfile(name: requestValue.name, imageURL: nil))
  }
}

struct SaveUserProfileUseCaseRequestValue {
  let name: String
  let imageData: Data?
}
