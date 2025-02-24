//
//  Product.swift
//  FreshNote
//
//  Created by SeokHyun on 10/30/24.
//

import Foundation

struct Product {
  let did: DocumentID
  let name: String
  let expirationDate: Date
  let category: String
  let memo: String?
  let imageURL: URL?
  let isPinned: Bool
  let creationDate: Date
}
