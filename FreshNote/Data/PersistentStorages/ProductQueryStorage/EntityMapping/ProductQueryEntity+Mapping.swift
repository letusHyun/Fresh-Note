//
//  ProductQueryEntity+Mapping.swift
//  FreshNote
//
//  Created by SeokHyun on 12/10/24.
//

import CoreData
import Foundation

extension ProductQueryEntity {
  convenience init(productQuery: ProductQuery, insertInto context: NSManagedObjectContext) {
    self.init(context: context)
    self.keyword = productQuery.keyword
    self.createdAt = Date()
    self.uuidString = productQuery.uuidString
  }
}

extension ProductQueryEntity {
  func toDomain() -> ProductQuery {
    return .init(
      keyword: self.keyword,
      uuidString: self.uuidString
    )
  }
}
