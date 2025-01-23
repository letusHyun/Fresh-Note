//
//  ProductResponseDTO.swift
//  FreshNote
//
//  Created by SeokHyun on 11/30/24.
//

import Foundation

struct ProductResponseDTO: Decodable {
  let name: String
  let memo: String?
  let imageURLString: String?
  let expirationDate: Date
  let category: String
  let isPinned: Bool
  let didString: String
  let creationDate: Date
}

extension ProductResponseDTO {
  func toDomain(did: DocumentID, url: URL?) -> Product {
    return Product(
      did: did,
      name: self.name,
      expirationDate: self.expirationDate,
      category: self.category,
      memo: self.memo,
      imageURL: url,
      isPinned: self.isPinned,
      creationDate: self.creationDate
    )
  }
}
