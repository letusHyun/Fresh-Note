//
//  DefaultProductRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 11/27/24.
//

import Combine
import Foundation

final class DefaultProductRepository: ProductRepository {
  private let firebaseNetworkService: any FirebaseNetworkService
  private let productStorage: any ProductStorage
  private let backgroundQueue: DispatchQueue
  
  init(
    firebaseNetworkService: any FirebaseNetworkService,
    productStorage: any ProductStorage,
    backgroundQueue: DispatchQueue = DispatchQueue.global(qos: .userInitiated)
  ) {
    self.firebaseNetworkService = firebaseNetworkService
    self.productStorage = productStorage
    self.backgroundQueue = backgroundQueue
  }
  
  deinit {
    print("DEBUG: \(Self.self) deinit")
  }
  
  func fetchProducts() -> AnyPublisher<[Product], any Error> {
    // 1. LocalDB fetch
    // 2. Firestore fetch → LocalDB save
    return self.productStorage
      .fetchProducts()
      .flatMap { [weak self] products -> AnyPublisher<[Product], any Error> in
        guard let self else {
          return Fail(error: CommonError.referenceError).eraseToAnyPublisher()
        }
        
        // storage에 entity 존재하지 않으면 api 호출
        if products.isEmpty {
          guard let userID = FirebaseUserManager.shared.userID else {
            return Fail(error: FirebaseUserError.invalidUid).eraseToAnyPublisher()
          }
          
          let fullPath = FirestorePath.products(userID: userID)
          
          // firestore fetch -> localDB save
          return self.firebaseNetworkService
            .getDocuments(collectionPath: fullPath)
            .receive(on: self.backgroundQueue)
            .map { (dtoArray: [ProductResponseDTO]) -> [Product] in
              return dtoArray.compactMap {
                self.convertProduct($0)
              }
            }
            .flatMap { products in
              return self.productStorage.saveProducts(with: products)
            }
            .eraseToAnyPublisher()
        }
        
        return Just(products)
          .setFailureType(to: Error.self)
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
  
  func saveProduct(product: Product) -> AnyPublisher<Void, any Error> {
    guard let userID = FirebaseUserManager.shared.userID else {
      return Fail(error: FirebaseUserError.invalidUid).eraseToAnyPublisher()
    }
    
    let urlString = product.imageURL?.absoluteString
    let didString = product.did.didString
    let fullPath = FirestorePath.product(userID: userID, productID: didString)
    
    let requestDTO = ProductRequestDTO(
      name: product.name,
      memo: product.memo,
      imageURLString: urlString,
      expirationDate: product.expirationDate,
      category: product.category.rawValue,
      isPinned: product.isPinned,
      didString: didString,
      creationDate: product.creationDate
    )
    
    return self.firebaseNetworkService
      .setDocument(documentPath: fullPath, requestDTO: requestDTO, merge: true)
      .flatMap { [weak self] in
        guard let self else {
          return Fail<Void, any Error>(error: CommonError.referenceError).eraseToAnyPublisher()
        }
        
        return self.productStorage.saveProduct(with: product)
      }
      .receive(on: self.backgroundQueue)
      .eraseToAnyPublisher()
  }
  
  /// firestore delete -> cache delete
  func deleteProduct(didString: String) -> AnyPublisher<Void, any Error> {
    guard let userID = FirebaseUserManager.shared.userID else {
      return Fail(error: FirebaseUserError.invalidUid).eraseToAnyPublisher()
    }
    
    let fullPath = FirestorePath.product(userID: userID, productID: didString)
    
    return self.firebaseNetworkService
      .deleteDocument(documentPath: fullPath)
      .flatMap { [weak self] in
        guard let self else {
          return Fail<Void, any Error>(error: CommonError.referenceError).eraseToAnyPublisher()
        }
        
        return self.productStorage.deleteProduct(uid: didString)
      }
      .receive(on: self.backgroundQueue)
      .eraseToAnyPublisher()
  }
  
  func updateProduct(product: Product) -> AnyPublisher<Product, any Error> {
    guard let userID = FirebaseUserManager.shared.userID else {
      return Fail(error: FirebaseUserError.invalidUid).eraseToAnyPublisher()
    }
    
    let urlString = product.imageURL?.absoluteString
    let didString = product.did.didString
    let fullPath = FirestorePath.product(userID: userID, productID: didString)
    
    let requestDTO = ProductRequestDTO(
      name: product.name,
      memo: product.memo,
      imageURLString: urlString,
      expirationDate: product.expirationDate,
      category: product.category.rawValue,
      isPinned: product.isPinned,
      didString: didString,
      creationDate: product.creationDate
    )
    
    return self.firebaseNetworkService
      .setDocument(documentPath: fullPath, requestDTO: requestDTO, merge: true)
      .flatMap { [weak self] in
        guard let self else {
          return Fail<Product, any Error>(error: CommonError.referenceError).eraseToAnyPublisher()
        }
        
        return self.productStorage.updateProduct(with: product)
      }
      .receive(on: self.backgroundQueue)
      .eraseToAnyPublisher()
  }
  
  func updateProductWithImageDeletion(product: Product) -> AnyPublisher<Product, any Error> {
    guard let userID = FirebaseUserManager.shared.userID else {
      return Fail(error: FirebaseUserError.invalidUid).eraseToAnyPublisher()
    }
    
    let urlString = product.imageURL?.absoluteString
    let didString = product.did.didString
    let fullPath = FirestorePath.product(userID: userID, productID: didString)
    
    let requestDTO = ProductRequestDTO(
      name: product.name,
      memo: product.memo,
      imageURLString: urlString,
      expirationDate: product.expirationDate,
      category: product.category.rawValue,
      isPinned: product.isPinned,
      didString: didString,
      creationDate: product.creationDate
    )
    
    return self.firebaseNetworkService
      .setDocument(documentPath: fullPath, requestDTO: requestDTO, merge: false)
      .flatMap { [weak self] in
        guard let self else {
          return Fail<Product, any Error>(error: CommonError.referenceError).eraseToAnyPublisher()
        }
        
        return self.productStorage.updateProduct(with: product)
      }
      .receive(on: self.backgroundQueue)
      .eraseToAnyPublisher()
  }
  
  func fetchProduct(productID: DocumentID) -> AnyPublisher<Product, any Error> {
    return self.productStorage
      .fetchProduct(didString: productID.didString)
  }
  
  func fetchPinnedProducts() -> AnyPublisher<[Product], any Error> {
    return self.productStorage
      .fetchPinnedProducts()
  }
  
  func fetchProduct(category: String) -> AnyPublisher<[Product], any Error> {
    return self.productStorage
      .fetchProduct(category: category)
  }
  
  func fetchProduct(keyword: String) -> AnyPublisher<[Product], any Error> {
    return self.productStorage
      .fetchProduct(keyword: keyword)
  }
  
  func deleteCachedProducts() -> AnyPublisher<[DocumentID], any Error> {
    return self.productStorage
      .fetchProducts()
      .flatMap { [weak self] products -> AnyPublisher<[DocumentID], any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }

        return products
          .publisher
          .flatMap { self.productStorage.deleteProduct(uid: $0.did.didString) }
          .collect()
          .map { _ in products.map { $0.did } }
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
}

// MARK: - Private Helpers
extension DefaultProductRepository {
  private func convertProduct(_ dto: ProductResponseDTO) -> Product? {
    guard let did = DocumentID(from: dto.didString) else { return nil }
    let imageURL = dto.imageURLString.flatMap { URL(string: $0) }
    
    return Product(
      did: did,
      name: dto.name,
      expirationDate: dto.expirationDate,
      category: ProductCategory(rawValue: dto.category) ?? ProductCategory.건강,
      memo: dto.memo,
      imageURL: imageURL,
      isPinned: dto.isPinned,
      creationDate: dto.creationDate
    )
  }
}
