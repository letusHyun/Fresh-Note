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
  
  /// 로그아웃 후, 로그인을 하면 localDB에 Products가 지워져있는 상태입니다.
  /// 따라서 다시 localDB에 Products를 저장해야 합니다.
  func fetchProducts() -> AnyPublisher<[Product], any Error> {
    // 1. 최초 로그인이면, Firestore fetch → LocalDB save
    // 2. 최초 로그인이 아니면, LocalDB fetch
    return self.productStorage.hasProducts()
      .flatMap { [weak self] hasProducts -> AnyPublisher<[Product], any Error> in
        guard let self else { return Empty().eraseToAnyPublisher() }
        
        // 최초 로그인이 아니면
        if hasProducts {
          return self.productStorage.fetchProducts()
        }
        
        guard let userID = FirebaseUserManager.shared.userID else {
          return Fail(error: FirebaseUserError.invalidUid).eraseToAnyPublisher()
        }
        
        let fullPath = FirestorePath.products(userID: userID)
        
        // 최초 로그인이면
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
      category: product.category,
      isPinned: product.isPinned,
      didString: didString,
      creationDate: product.creationDate
    )

    return self.firebaseNetworkService
      .setDocument(documentPath: fullPath, requestDTO: requestDTO, merge: true)
      .flatMap { [weak self] in
        guard let self else { return Empty<Void, any Error>().eraseToAnyPublisher() }
        
        return self.productStorage.saveProduct(with: product)
      }
      .receive(on: self.backgroundQueue)
      .eraseToAnyPublisher()
  }
  
  func deleteProduct(didString: String) -> AnyPublisher<Void, any Error> {
    guard let userID = FirebaseUserManager.shared.userID else {
      return Fail(error: FirebaseUserError.invalidUid).eraseToAnyPublisher()
    }
    
    let fullPath = FirestorePath.product(userID: userID, productID: didString)
    
    return self.firebaseNetworkService
      .deleteDocument(documentPath: fullPath)
      .flatMap { [weak self] in
        guard let self else { return Empty<Void, any Error>().eraseToAnyPublisher() }
        
        return self.productStorage.deleteProduct(uid: didString)
      }
      .receive(on: self.backgroundQueue)
      .eraseToAnyPublisher()
  }
  
  // TODO: - 제품 update usecase, repository 구현하기, vm도 업데이트하는 것으로 수정하기
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
      category: product.category,
      isPinned: product.isPinned,
      didString: didString,
      creationDate: product.creationDate
    )

    return self.firebaseNetworkService
      .setDocument(documentPath: fullPath, requestDTO: requestDTO, merge: true)
      .flatMap { [weak self] in
        guard let self else { return Empty<Product, any Error>().eraseToAnyPublisher() }
        
        return self.productStorage.updateProduct(with: product)
      }
      .receive(on: self.backgroundQueue)
      .eraseToAnyPublisher()
  }
  
  func fetchProduct(productID: DocumentID) -> AnyPublisher<Product, any Error> {
    return self.productStorage
      .fetchProduct(didString: productID.didString)
      .receive(on: self.backgroundQueue)
      .eraseToAnyPublisher()
  }
  
  func fetchPinnedProducts() -> AnyPublisher<[Product], any Error> {
    return self.productStorage
      .fetchPinnedProducts()
      .receive(on: self.backgroundQueue)
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
      category: dto.category,
      memo: dto.memo,
      imageURL: imageURL,
      isPinned: dto.isPinned,
      creationDate: dto.creationDate
    )
  }
}
