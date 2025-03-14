//
//  FetchProductUseCaseMock.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import Combine
import Foundation

final class FetchProductUseCaseMock: FetchProductUseCase {
  private(set) var fetchProductsCallCount = 0
  private(set) var fetchProductCallCount = 0
  private(set) var fetchProductByCategoryCallCount = 0
  private(set) var fetchProductByKeywordCallCount = 0
  private(set) var fetchPinnedProductsCallCount = 0
  
  private(set) var lastFetchSort: FetchProductSort?
  private(set) var lastFetchProductID: DocumentID?
  private(set) var lastFetchCategory: ProductCategory?
  private(set) var lastFetchKeyword: String?
  
  var fetchProductsResult: AnyPublisher<[Product], any Error>!
  var fetchProductResult: AnyPublisher<Product, any Error>!
  var fetchProductByCategoryResult: AnyPublisher<[Product], any Error>!
  var fetchProductByKeywordResult: AnyPublisher<[Product], any Error>!
  var fetchPinnedProductsResult: AnyPublisher<[Product], any Error>!
  
  func resetCallCounts() {
    self.fetchProductsCallCount = 0
    self.fetchProductCallCount = 0
    self.fetchProductByCategoryCallCount = 0
    self.fetchProductByKeywordCallCount = 0
    self.fetchPinnedProductsCallCount = 0
    
    self.lastFetchSort = nil
    self.lastFetchProductID = nil
    self.lastFetchCategory = nil
    self.lastFetchKeyword = nil
  }
  
  func fetchProducts(sort: FetchProductSort) -> AnyPublisher<[Product], any Error> {
    self.fetchProductsCallCount += 1
    self.lastFetchSort = sort
    return self.fetchProductsResult
  }
  
  func fetchProduct(productID: DocumentID) -> AnyPublisher<Product, any Error> {
    self.fetchProductCallCount += 1
    self.lastFetchProductID = productID
    return self.fetchProductResult
  }
  
  func fetchProduct(category: ProductCategory) -> AnyPublisher<[Product], any Error> {
    self.fetchProductByCategoryCallCount += 1
    self.lastFetchCategory = category
    return self.fetchProductByCategoryResult
  }
  
  func fetchProduct(keyword: String) -> AnyPublisher<[Product], any Error> {
    self.fetchProductByKeywordCallCount += 1
    self.lastFetchKeyword = keyword
    return self.fetchProductByKeywordResult
  }
  
  func fetchPinnedProducts() -> AnyPublisher<[Product], any Error> {
    self.fetchPinnedProductsCallCount += 1
    return self.fetchPinnedProductsResult
  }
} 