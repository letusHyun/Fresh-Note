//
//  CoreDataProductStorage.swift
//  FreshNote
//
//  Created by SeokHyun on 12/12/24.
//

import Combine
import CoreData
import Foundation

final class CoreDataProductStorage {
  private let coreDataStorage: any CoreDataStorage
  
  init(coreDataStorage: any CoreDataStorage) {
    self.coreDataStorage = coreDataStorage
  }
  
  private func deleteResponse(request: NSFetchRequest<ProductEntity>, in context: NSManagedObjectContext) throws {
    do {
      let results = try context.fetch(request)
      results.forEach { context.delete($0) }
      try context.save()
    } catch {
      throw CoreDataStorageError.deleteError(error)
    }
  }
}

// MARK: - ProductStorage
extension CoreDataProductStorage: ProductStorage {
  func hasProducts() -> AnyPublisher<Bool, any Error> {
    return self.coreDataStorage.performBackgroundTask { context in
      let request = ProductEntity.fetchRequest()
      
      do {
        let count = try context.count(for: request)
        return count > 0
      } catch {
        throw CoreDataStorageError.contextCountError(error)
      }
    }
  }
  
  func saveProduct(with product: Product) -> AnyPublisher<Void, any Error> {
    return self.coreDataStorage.performBackgroundTask { context in
      _ = ProductEntity(product: product, createdAt: Date(), insertInto: context)
      do {
        try context.save()
      } catch {
        throw CoreDataStorageError.saveError(error)
      }
    }
  }
  
  func saveProducts(with products: [Product]) -> AnyPublisher<[Product], any Error> {
    return self.coreDataStorage.performBackgroundTask { [weak self] context in
      let request = ProductEntity.fetchRequest()
      try self?.deleteResponse(request: request, in: context)
      
      products.forEach { product in
        _ = ProductEntity(product: product, createdAt: Date(), insertInto: context)
      }
      
      do {
        try context.save()
        return products
      } catch {
        throw CoreDataStorageError.saveError(error)
      }
    }
  }
  
  func fetchProducts() -> AnyPublisher<[Product], any Error> {
    return self.coreDataStorage.performBackgroundTask { context in
      let request = ProductEntity.fetchRequest()
      
      do {
        let entities = try context.fetch(request)
        return entities.map { $0.toDomain() }
      } catch {
        throw CoreDataStorageError.readError(error)
      }
    }
  }
  
  func deleteProduct(uid: String) -> AnyPublisher<Void, any Error> {
    return self.coreDataStorage.performBackgroundTask { [weak self] context in
      let request = ProductEntity.fetchRequest()
      request.predicate = NSPredicate(
        format: "\(ProductEntity.PropertyName.didString.rawValue) == %@",
        uid
      )
      
      try self?.deleteResponse(request: request, in: context)
    }
  }
  
  func updateProduct(with updatedProduct: Product) -> AnyPublisher<Product, any Error> {
    return self.coreDataStorage.performBackgroundTask { context in
      let request = ProductEntity.fetchRequest()
      request.predicate = NSPredicate(
        format: "\(ProductEntity.PropertyName.didString.rawValue) == %@",
        updatedProduct.did.didString
      )
      
      do {
        let entities = try context.fetch(request).first
        guard let entity = entities else {
          throw CoreDataStorageError.noEntity
        }
        let imageURLString = updatedProduct.imageURL.map { $0.absoluteString }
        
        entity.imageURLString = imageURLString
        entity.name = updatedProduct.name
        entity.memo = updatedProduct.memo
        entity.isPinned = updatedProduct.isPinned
        entity.expirationDate = updatedProduct.expirationDate
        entity.createdAt = updatedProduct.creationDate
        entity.category = updatedProduct.category
        
        return updatedProduct
      } catch {
        throw CoreDataStorageError.updateError(error)
      }
    }
  }
  
}
