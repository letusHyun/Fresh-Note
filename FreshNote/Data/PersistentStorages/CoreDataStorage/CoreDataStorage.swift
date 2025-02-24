//
//  CoreDataStorage.swift
//  FreshNote
//
//  Created by SeokHyun on 12/12/24.
//

import Combine
import CoreData
import Foundation

protocol CoreDataStorage {
  func performBackgroundTask<T>(
    _ block: @escaping (NSManagedObjectContext) throws -> T
  ) -> AnyPublisher<T, any Error>
}

extension CoreDataStorage {
  static var name: String { "CoreDataStorage" }
}

enum CoreDataStorageError: Error {
  case readError(Error)
  case saveError(Error)
  case deleteError(Error)
  case updateError(Error)
  case noEntity
  case contextCountError(Error)
}
