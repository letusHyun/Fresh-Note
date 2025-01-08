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
  
  // MARK: - Private
//  private func deleteResponse(in context: NSManagedObjectContext) throws {
//    let request = ProductQueryEntity.fetchRequest()
//    
//    do {
//      if let result = try context.fetch(request).first {
//        context.delete(result)
//      }
//    } catch {
//      throw CoreDataStorageError.deleteError(error)
//    }
//  }
}

// MARK: - ProductQueryStorage
extension CoreDataProductQueryStorage: ProductQueryStorage {
  func saveQuery(productQuery: ProductQuery) -> AnyPublisher<ProductQuery, any Error> {
    return self.coreDataStorage
      .performBackgroundTask { [weak self] context -> ProductQuery in
//        try self?.deleteResponse(in: context)
        
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
}
