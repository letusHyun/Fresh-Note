//
//  CoreDataUserProfileStorage.swift
//  FreshNote
//
//  Created by SeokHyun on 12/13/24.
//

import Combine
import CoreData
import Foundation

final class CoreDataUserProfileStorage {
  private let coreDataStorage: any CoreDataStorage
  
  init(coreDataStorage: any CoreDataStorage) {
    self.coreDataStorage = coreDataStorage
  }
  
  // MARK: - Private
  private func deleteResponse(in context: NSManagedObjectContext) {
    let request = UserProfileEntity.fetchRequest()
    
    do {
      if let result = try context.fetch(request).first {
        context.delete(result)
      }
    }
    catch {
      print("DEBUG: CoreDataUserProfileStorage fetch error:\(error)")
    }
  }
}

// MARK: - UserProfileStorage
extension CoreDataUserProfileStorage: UserProfileStorage {
  func hasUserProfile() -> AnyPublisher<Bool, any Error> {
    return self.coreDataStorage.performBackgroundTask { context in
      let request = UserProfileEntity.fetchRequest()
      
      do {
        let count = try context.count(for: request)
        return count > 0
      } catch {
        throw CoreDataStorageError.contextCountError(error)
      }
    }
  }
  
  func saveUserProfile(userProfile: UserProfile) -> AnyPublisher<UserProfile, any Error> {
    return self.coreDataStorage
      .performBackgroundTask { [weak self] context in
        self?.deleteResponse(in: context)
        
        _ = UserProfileEntity(userProfile: userProfile, insertInto: context)
        do {
          try context.save()
          return userProfile
        } catch {
          throw CoreDataStorageError.saveError(error)
        }
      }
  }
  
  func fetchUserProfile() -> AnyPublisher<UserProfile, any Error> {
    return self.coreDataStorage
      .performBackgroundTask { context in
        let request = UserProfileEntity.fetchRequest()
        
        do {
          let entities = try context.fetch(request)
          guard let userProfile = entities.first?.toDomain() else {
            throw CoreDataStorageError.noEntity
          }
          return userProfile
        } catch {
          throw CoreDataStorageError.readError(error)
        }
      }
  }
  
  func updateProfile(updatedUserProfile: UserProfileRequestDTO) -> AnyPublisher<UserProfile, any Error> {
    return self.coreDataStorage.performBackgroundTask { context in
      let request = UserProfileEntity.fetchRequest()
      do {
        let entities = try context.fetch(request)
        guard let entity = entities.first else {
          throw CoreDataStorageError.noEntity
        }
        entity.name = updatedUserProfile.name
        entity.imageURLString = updatedUserProfile.imageURLString
        try context.save()
        
        let url = updatedUserProfile.imageURLString.flatMap { URL(string: $0) }
        return UserProfile(name: updatedUserProfile.name, imageURL: url)
      } catch {
        throw CoreDataStorageError.updateError(error)
      }
    }
  }
}
