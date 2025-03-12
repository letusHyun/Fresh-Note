//
//  InMemoryCoreDataStorage.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/12/25.
//

@testable import Fresh_Note_Dev
import CoreData
import Combine
import Foundation

final class InMemoryCoreDataStorage: CoreDataStorage {
  private let persistentContainer: NSPersistentContainer
  
  static let shared: CoreDataStorage = InMemoryCoreDataStorage()
  
  private init() {
    self.persistentContainer = NSPersistentContainer(name: "Fresh_Note_Dev")
    let description = NSPersistentStoreDescription()
    description.type = NSInMemoryStoreType // 인메모리 형식
    self.persistentContainer.persistentStoreDescriptions = [description]
    self.persistentContainer.loadPersistentStores { _, error in
      if let error = error {
        fatalError("Failed to load in-memory store: \(error)")
      }
    }
  }
  
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
