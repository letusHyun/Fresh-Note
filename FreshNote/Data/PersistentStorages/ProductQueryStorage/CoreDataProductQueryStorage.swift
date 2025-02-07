//
//  CoreDataProductQueryStorage.swift
//  FreshNote
//
//  Created by SeokHyun on 12/10/24.
//

import Combine
import CoreData
import Foundation

final class CoreDataProductQueryStorage {
  private let coreDataStorage: any CoreDataStorage
  
  init(coreDataStorage: any CoreDataStorage) {
    self.coreDataStorage = coreDataStorage
  }
  
  deinit {
    print("DEBUG: \(Self.self) deinit")
  }
}

// MARK: - ProductQueryStorage
extension CoreDataProductQueryStorage: ProductQueryStorage {
  func deleteAll() -> AnyPublisher<Void, any Error> {
    return self.coreDataStorage.performBackgroundTask { context in
      let request = ProductQueryEntity.fetchRequest()
      
      do {
        let entities = try context.fetch(request)
        entities.forEach { context.delete($0) }
        try context.save()
      } catch {
        throw CoreDataStorageError.deleteError(error)
      }
    }
  }
  
  func saveQuery(productQuery: ProductQuery) -> AnyPublisher<ProductQuery, any Error> {
    return self.coreDataStorage
      .performBackgroundTask { context -> ProductQuery in
        _ = ProductQueryEntity(productQuery: productQuery, insertInto: context)
        
        do {
          try context.save()
          return productQuery
        } catch {
          throw CoreDataStorageError.saveError(error)
        }
      }
      .eraseToAnyPublisher()
  }
  
  func fetchQueries() -> AnyPublisher<[ProductQuery], any Error> {
    self.coreDataStorage
      .performBackgroundTask { context -> [ProductQuery] in
        let request: NSFetchRequest<ProductQueryEntity> = ProductQueryEntity.fetchRequest()
        request.sortDescriptors = [
          NSSortDescriptor(key: ProductQueryEntity.PropertyName.createdAt.rawValue, ascending: true)
        ]
        
        do {
          let entities = try context.fetch(request)
          return entities.map { $0.toDomain() }
        } catch {
          throw CoreDataStorageError.readError(error)
        }
      }
      .eraseToAnyPublisher()
  }
  
  func deleteQuery(uuidString: String) -> AnyPublisher<Void, any Error> {
    self.coreDataStorage
      .performBackgroundTask { context -> Void in
        let request: NSFetchRequest<ProductQueryEntity> = ProductQueryEntity.fetchRequest()
        request.predicate = NSPredicate(
          format: "\(ProductQueryEntity.PropertyName.uuidString.rawValue) == %@",
          uuidString
        )
        let entities = try context.fetch(request)
        
        guard !entities.isEmpty else {
          throw CoreDataStorageError.noEntity
        }
        
        entities.forEach { entity in
          context.delete(entity)
        }
        
        do {
          try context.save()
        } catch {
          throw CoreDataStorageError.saveError(error)
        }
      }
  }
  
  func deleteQueries() -> AnyPublisher<Void, any Error> {
    self.coreDataStorage
      .performBackgroundTask { context -> Void in
        do {
          let request: NSFetchRequest<ProductQueryEntity> = ProductQueryEntity.fetchRequest()
          let entities = try context.fetch(request)
          
          entities.forEach { entity in
            context.delete(entity)
          }
          try context.save()
        } catch {
          throw CoreDataStorageError.saveError(error)
        }
      }
  }
}
