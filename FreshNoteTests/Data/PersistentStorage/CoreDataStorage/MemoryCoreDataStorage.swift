//
//  MemoryCoreDataStorage.swift
//  FreshNote
//
//  Created by SeokHyun on 12/12/24.
//

import Combine
import CoreData
import Foundation

/// 인메모리 방식으로 CRUD를 수행합니다.
final class MemoryCoreDataStorage: CoreDataStorage {
  static let shared: CoreDataStorage = MemoryCoreDataStorage()
  
  private lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: Self.name)
    let description = NSPersistentStoreDescription()
    description.type = NSInMemoryStoreType
    container.persistentStoreDescriptions = [description]
    
    container.loadPersistentStores { _, error in
      if let error = error {
        fatalError("CoreData store failed to load: \(error.localizedDescription)")
      }
    }
    return container
  }()

  func performBackgroundTask<T>(
    _ block: @escaping (NSManagedObjectContext) throws -> T
  ) -> AnyPublisher<T, any Error> {
    return Future { [weak self] promise in
      self?.persistentContainer.performBackgroundTask { context in
        do {
          let result = try block(context)
          return promise(.success(result))
        } catch {
          return promise(.failure(error))
        }
      }
    }
    .eraseToAnyPublisher()
  }
}
