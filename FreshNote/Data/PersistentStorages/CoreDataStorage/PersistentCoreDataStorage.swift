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
    _ getResult: @escaping (NSManagedObjectContext) throws -> T
  ) -> AnyPublisher<T, any Error> {
    Deferred {
      return Future { [weak self] promise in
        guard let self else { return promise(.failure(CommonError.referenceError)) }
        
        self.persistentContainer.performBackgroundTask { context in
          do {
            let result = try getResult(context)
            return promise(.success(result))
          } catch {
            return promise(.failure(error))
          }
        }
      }
    }
    .eraseToAnyPublisher()
  }
}
