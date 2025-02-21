//
//  FetchProductUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 11/30/24.
//

import Combine
import Foundation

enum FetchProductSort {
  // 업로드 순 + 유통기한 지나면 후순
  case `default`
  // 유통기한 순서
  case expiration
}

protocol FetchProductUseCase {
  func fetchProducts(sort: FetchProductSort) -> AnyPublisher<[Product], any Error>
  func fetchProduct(productID: DocumentID) -> AnyPublisher<Product, any Error>
  func fetchPinnedProducts() -> AnyPublisher<[Product], any Error>
  func fetchProduct(category: ProductCategory) -> AnyPublisher<[Product], any Error>
  func fetchProduct(keyword: String) -> AnyPublisher<[Product], any Error>
}

final class DefaultFetchProductUseCase: FetchProductUseCase {
  private let productRepository: any ProductRepository
  
  init(
    productRepository: any ProductRepository
  ) {
    self.productRepository = productRepository
  }
  
  func fetchProducts(sort: FetchProductSort) -> AnyPublisher<[Product], any Error> {
    return self.productRepository
      .fetchProducts()
      
      .map { (products: [Product]) -> [Product] in
        switch sort {
        case .default:
          let now = Date()
          
          return products.sorted { (p1: Product, p2: Product) -> Bool in
            let p1Expired = p1.expirationDate < now
            let p2Expired = p2.expirationDate < now
            
            if p1Expired != p2Expired {
              return !p1Expired
            } else {
              return p1.creationDate > p2.creationDate
            }
          }
        case .expiration:
          return products.sorted {
            $0.expirationDate < $1.expirationDate
          }
        }
      }
      .eraseToAnyPublisher()
  }
  
  func fetchProduct(productID: DocumentID) -> AnyPublisher<Product, any Error> {
    return self.productRepository
      .fetchProduct(productID: productID)
  }
  
  func fetchPinnedProducts() -> AnyPublisher<[Product], any Error> {
    return self.productRepository
      .fetchPinnedProducts()
  }
  
  func fetchProduct(category: ProductCategory) -> AnyPublisher<[Product], any Error> {
    return productRepository
      .fetchProduct(category: category.rawValue)
  }
  
  func fetchProduct(keyword: String) -> AnyPublisher<[Product], any Error> {
    return productRepository
      .fetchProduct(keyword: keyword)
  }
}
