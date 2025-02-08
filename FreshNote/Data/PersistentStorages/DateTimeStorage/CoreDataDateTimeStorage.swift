//
//  CoreDataDateTimeStorage.swift
//  FreshNote
//
//  Created by SeokHyun on 1/11/25.
//

import Combine
import CoreData
import Foundation

final class CoreDataDateTimeStorage: DateTimeStorage {
  private let coreDataStorage: any CoreDataStorage
  
  init(coreDataStorage: any CoreDataStorage) {
    self.coreDataStorage = coreDataStorage
  }
  
  func saveDateTime(dateTime: DateTime) -> AnyPublisher<DateTime, any Error> {
    return self.coreDataStorage.performBackgroundTask { context in
      _ = DateTimeEntity(dateTime: dateTime, insertInto: context)
      
      do {
        try context.save()
        return dateTime
      } catch {
        throw CoreDataStorageError.saveError(error)
      }
    }
  }
  
  func updateDateTime(dateTime: DateTime) -> AnyPublisher<DateTime, any Error> {
    return self.coreDataStorage.performBackgroundTask { context in
      let request = DateTimeEntity.fetchRequest()
      
      do {
        let entities = try context.fetch(request).first
        guard let entity = entities else {
          throw CoreDataStorageError.noEntity
        }
        entity.date = Int16(dateTime.date)
        entity.hour = Int16(dateTime.hour)
        entity.minute = Int16(dateTime.minute)
        
        try context.save()
        return dateTime
      } catch {
        throw CoreDataStorageError.updateError(error)
      }
    }
  }
  
  func fetchDateTime() -> AnyPublisher<DateTime, any Error> {
    return self.coreDataStorage.performBackgroundTask { context in
      let request = DateTimeEntity.fetchRequest()
      
      do {
        let entities = try context.fetch(request).first
        guard let entity = entities else {
          throw CoreDataStorageError.noEntity
        }
        return entity.toDomain()
      } catch {
        throw CoreDataStorageError.readError(error)
      }
    }
  }
  
  func deleteDateTime() -> AnyPublisher<Void, any Error> {
    return self.coreDataStorage.performBackgroundTask { context in
      let request = DateTimeEntity.fetchRequest()
      
      do {
        let entities = try context.fetch(request)
        entities.forEach { context.delete($0) }
        try context.save()
      } catch {
        throw CoreDataStorageError.deleteError(error)
      }
    }
  }
}
