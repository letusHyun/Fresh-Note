//
//  ProductRepositoryMock.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import Combine
import Foundation

final class ProductRepositoryMock: ProductRepository {
  private(set) var saveProductCallCount = 0
  private(set) var fetchProductsCallCount = 0
  private(set) var fetchProductByIDCallCount = 0
  private(set) var deleteProductCallCount = 0
  private(set) var updateProductCallCount = 0
  private(set) var updateProductWithImageDeletionCallCount = 0
  private(set) var fetchPinnedProductsCallCount = 0
  private(set) var fetchProductByCategoryCallCount = 0
  private(set) var fetchProductByKeywordCallCount = 0
  private(set) var deleteCachedProductsCallCount = 0
  
  private(set) var lastDeletedDidString: String?
  private(set) var lastSavedProduct: Product?
  
  var saveProductResult: AnyPublisher<Void, any Error>!
  var fetchProductsResult: AnyPublisher<[Product], any Error>!
  var fetchProductByIDResult: AnyPublisher<Product, any Error>!
  var deleteProductResult: AnyPublisher<Void, any Error>!
  var updateProductResult: AnyPublisher<Product, any Error>!
  var updateProductWithImageDeletionResult: AnyPublisher<Product, any Error>!
  var fetchPinnedProductsResult: AnyPublisher<[Product], any Error>!
  var fetchProductByCategoryResult: AnyPublisher<[Product], any Error>!
  var fetchProductByKeywordResult: AnyPublisher<[Product], any Error>!
  var deleteCachedProductsResult: AnyPublisher<[DocumentID], any Error>!
  
  func resetCallCounts() {
    self.saveProductCallCount = 0
    self.fetchProductsCallCount = 0
    self.fetchProductByIDCallCount = 0
    self.deleteProductCallCount = 0
    self.updateProductCallCount = 0
    self.updateProductWithImageDeletionCallCount = 0
    self.fetchPinnedProductsCallCount = 0
    self.fetchProductByCategoryCallCount = 0
    self.fetchProductByKeywordCallCount = 0
    self.deleteCachedProductsCallCount = 0
    
    self.lastDeletedDidString = nil
    self.lastSavedProduct = nil
  }
  
  func saveProduct(product: Product) -> AnyPublisher<Void, any Error> {
    self.saveProductCallCount += 1
    self.lastSavedProduct = product
    return self.saveProductResult
  }
  
  func fetchProducts() -> AnyPublisher<[Product], any Error> {
    self.fetchProductsCallCount += 1
    return self.fetchProductsResult
  }
  
  func fetchProduct(productID: DocumentID) -> AnyPublisher<Product, any Error> {
    self.fetchProductByIDCallCount += 1
    return self.fetchProductByIDResult
  }
  
  func deleteProduct(didString: String) -> AnyPublisher<Void, any Error> {
    self.deleteProductCallCount += 1
    self.lastDeletedDidString = didString
    return self.deleteProductResult
  }
  
  func updateProduct(product: Product) -> AnyPublisher<Product, any Error> {
    self.updateProductCallCount += 1
    return self.updateProductResult
  }
  
  func updateProductWithImageDeletion(product: Product) -> AnyPublisher<Product, any Error> {
    self.updateProductWithImageDeletionCallCount += 1
    return self.updateProductWithImageDeletionResult
  }
  
  func fetchPinnedProducts() -> AnyPublisher<[Product], any Error> {
    self.fetchPinnedProductsCallCount += 1
    return self.fetchPinnedProductsResult
  }
  
  func fetchProduct(category: String) -> AnyPublisher<[Product], any Error> {
    self.fetchProductByCategoryCallCount += 1
    return self.fetchProductByCategoryResult
  }
  
  func fetchProduct(keyword: String) -> AnyPublisher<[Product], any Error> {
    self.fetchProductByKeywordCallCount += 1
    return self.fetchProductByKeywordResult
  }
  
  func deleteCachedProducts() -> AnyPublisher<[DocumentID], any Error> {
    self.deleteCachedProductsCallCount += 1
    return self.deleteCachedProductsResult
  }
} 