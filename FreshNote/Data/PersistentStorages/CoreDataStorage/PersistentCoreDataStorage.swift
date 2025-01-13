//
//  PersistentCoreDataStorage.swift
//  FreshNote
//
//  Created by SeokHyun on 12/7/24.
//

import Combine
import CoreData
import Foundation

/// 같은 context 접근을 위해서 shared를 사용해야 합니다.
final class PersistentCoreDataStorage: CoreDataStorage {
  static let shared: CoreDataStorage = PersistentCoreDataStorage()
  
  private lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: Self.name)
    
    container.loadPersistentStores { _, error in
      if let error = error {
        fatalError("CoreData store failed to load: \(error.localizedDescription)")
      }
    }
    return container
  }()
  
  private init() { }
  
  func performBackgroundTask<T>(
    _ block: @escaping (NSManagedObjectContext) throws -> T
  ) -> AnyPublisher<T, any Error> {
    return Future { [weak self] promise in
      self?.persistentContainer.performBackgroundTask { context in
        do {
          let result = try block(context)
          promise(.success(result))
        } catch {
          promise(.failure(error))
        }
      }
    }
    .eraseToAnyPublisher()
  }
}
