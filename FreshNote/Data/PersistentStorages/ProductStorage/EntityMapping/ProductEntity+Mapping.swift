//
//  ProductEntity+Mapping.swift
//  FreshNote
//
//  Created by SeokHyun on 12/13/24.
//

import CoreData
import Foundation

extension ProductEntity {
  convenience init(product: Product, createdAt: Date, insertInto context: NSManagedObjectContext) {
    self.init(context: context)
    self.name = product.name
    self.memo = product.memo
    self.isPinned = product.isPinned
    self.category = product.category.rawValue
    self.expirationDate = product.expirationDate
    self.didString = product.did.didString
    self.createdAt = createdAt
    
    guard let url = product.imageURL else {
      self.imageURLString = nil
      return
    }
    
    self.imageURLString = url.absoluteString
  }
}

// MARK: - Mapping To Domain
extension ProductEntity {
  func toDomain() -> Product {
    let imageURL = self.imageURLString.flatMap { URL(string: $0) }
    return Product(
      did: DocumentID(from: self.didString) ?? DocumentID(),
      name: self.name,
      expirationDate: self.expirationDate,
      category: ProductCategory(rawValue: self.category) ?? .건강,
      memo: self.memo,
      imageURL: imageURL,
      isPinned: self.isPinned,
      creationDate: self.createdAt
    )
  }
}
