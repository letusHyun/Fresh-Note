//
//  FirestorePath.swift
//  FreshNote
//
//  Created by SeokHyun on 11/11/24.
//

import Foundation
import FirebaseFirestore

enum FirestorePath: String {
  case users
  case products
  
  static func userID(userID: String) -> String {
    return "\(users.rawValue)/\(userID)"
  }
  
  static func products(userID: String) -> String {
    return "\(users.rawValue)/\(userID)/\(products.rawValue)"
  }
  
  static func product(userID: String, productID: String) -> String {
    return "\(users.rawValue)/\(userID)/\(products.rawValue)/\(productID)"
  }
}
