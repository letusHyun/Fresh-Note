//
//  ProductRequestDTO.swift
//  FreshNote
//
//  Created by SeokHyun on 11/28/24.
//

import Foundation

struct ProductRequestDTO: Encodable {
  let name: String
  let memo: String?
  let imageURLString: String?
  let expirationDate: Date
  let category: String
  let isPinned: Bool
  let didString: String
  let creationDate: Date
}
