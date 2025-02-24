//
//  DefaultUserProfileRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 12/13/24.
//

import Combine
import Foundation

final class DefaultUserProfileRepository: UserProfileRepository {
  private let userProfileStorage: any UserProfileStorage
  private let firebaseNetworkService: any FirebaseNetworkService
  private let backgroundQueue: DispatchQueue
  
  init(
    userProfileStorage: any UserProfileStorage,
    firebaseNetworkService: any FirebaseNetworkService,
    backgroundQueue: DispatchQueue = .global(qos: .userInitiated)
  ) {
    self.userProfileStorage = userProfileStorage
    self.firebaseNetworkService = firebaseNetworkService
    self.backgroundQueue = backgroundQueue
  }
  
  func fetchUserProfile() -> AnyPublisher<UserProfile, any Error> {
    self.userProfileStorage.hasUserProfile()
      .flatMap { [weak self] hasUserProfile -> AnyPublisher<UserProfile, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        
        // 최초 로그인이 아니면
        if hasUserProfile {
          return self.userProfileStorage
            .fetchUserProfile()
            .receive(on: self.backgroundQueue)
            .eraseToAnyPublisher()
        }
        
        // 최초 로그인이면
        guard let userID = FirebaseUserManager.shared.userID else {
          return Fail(error: FirebaseUserError.invalidUid).eraseToAnyPublisher()
        }
        
        let fullPath = FirestorePath.products(userID: userID)
        
        // firestore fetch -> localDB save
        return self.firebaseNetworkService
          .getDocument(documentPath: fullPath)
          .receive(on: self.backgroundQueue)
          .map { (responseDTO: UserProfileResponseDTO) -> UserProfile in
            return responseDTO.toDomain()
          }
          .flatMap { userProfile in
            return self.userProfileStorage
              .saveUserProfile(userProfile: userProfile)
          }
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
  
  func saveUserProfile(userProfile: UserProfile) -> AnyPublisher<UserProfile, any Error> {
    guard let userID = FirebaseUserManager.shared.userID else {
      return Fail(error: FirebaseUserError.invalidUid).eraseToAnyPublisher()
    }
    
    let fullPath = FirestorePath.userID(userID: userID)
    let imageURLString = userProfile.imageURL?.absoluteString
    let requestDTO = UserProfileRequestDTO(name: userProfile.name, imageURLString: imageURLString)
    
    return self.firebaseNetworkService
      .setDocument(documentPath: fullPath, requestDTO: requestDTO, merge: true)
      .receive(on: self.backgroundQueue)
      .flatMap { [weak self] in
        guard let self else {
          return Fail<UserProfile, any Error>(error: CommonError.referenceError).eraseToAnyPublisher()
        }
        
        return self.userProfileStorage
          .saveUserProfile(userProfile: userProfile)
      }
      .eraseToAnyPublisher()
  }
  
  func updateUserProfile(updatedUserProfile: UserProfile) -> AnyPublisher<UserProfile, any Error> {
    guard let userID = FirebaseUserManager.shared.userID else {
      return Fail(error: FirebaseUserError.invalidUid).eraseToAnyPublisher()
    }
    
    let fullPath = FirestorePath.userID(userID: userID)
    let requestDTO = UserProfileRequestDTO(
      name: updatedUserProfile.name,
      imageURLString: updatedUserProfile.imageURL?.absoluteString
    )
    
    return self.firebaseNetworkService
      .setDocument(documentPath: fullPath, requestDTO: requestDTO, merge: true)
      .flatMap { [weak self] in
        guard let self else {
          return Fail<UserProfile, any Error>(error: CommonError.referenceError).eraseToAnyPublisher()
        }
        
        return self.userProfileStorage.updateProfile(updatedUserProfile: requestDTO)
      }
      .eraseToAnyPublisher()
  }
}
