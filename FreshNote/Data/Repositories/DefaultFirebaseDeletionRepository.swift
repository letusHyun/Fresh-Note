//
//  DefaultFirebaseDeletionRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 2/3/25.
//

import Combine
import Foundation

final class DefaultFirebaseDeletionRepository: FirebaseDeletionRepository {
  private let firebaseNetworkService: any FirebaseNetworkService
  private let backgroundQueue: DispatchQueue
  
  init(
    firebaseNetworkService: any FirebaseNetworkService,
    backgroundQueue: DispatchQueue = .global(qos: .userInitiated)
  ) {
    self.firebaseNetworkService = firebaseNetworkService
    self.backgroundQueue = backgroundQueue
  }
  
  
  func deleteUserWithAllData() -> AnyPublisher<Void, any Error> {
    guard let userID = FirebaseUserManager.shared.userID else {
      return Fail(error: FirebaseUserError.invalidUid).eraseToAnyPublisher()
    }
    
    // 1. products collection의 모든 document 가져오기
    return self.firebaseNetworkService
      .getDocuments(collectionPath: FirestorePath.products(userID: userID))
      .flatMap { [weak self] (products: [ProductResponseDTO]) -> AnyPublisher<Void, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        
        // 2. 각 product의 이미지와 document 삭제
        let deleteOperations = products.map { product -> AnyPublisher<Void, any Error> in
          // 이미지가 있는 경우 이미지 먼저 삭제
          if let imageURLString = product.imageURLString {
            return self.firebaseNetworkService
              .deleteData(urlString: imageURLString)
              .flatMap { _ -> AnyPublisher<Void, Error> in
                // 이미지 삭제 후 document 삭제
                return self.firebaseNetworkService.deleteDocument(
                  documentPath: FirestorePath.product(userID: userID, productID: product.didString)
                )
              }
              .eraseToAnyPublisher()
          } else {
            // 이미지가 없는 경우 document만 삭제
            return self.firebaseNetworkService
              .deleteDocument(documentPath: FirestorePath.product(
                userID: userID,
                productID: product.didString)
              )
          }
        }
        
        // 모든 삭제 작업 완료 대기
        return Publishers.MergeMany(deleteOperations)
          .collect()
          .map { _ in () }
          .eraseToAnyPublisher()
      }
    // 3. 모든 하위 데이터가 삭제된 후 user document 삭제
      .flatMap { _ -> AnyPublisher<Void, Error> in
        self.firebaseNetworkService.deleteDocument(
          documentPath: FirestorePath.userID(userID: userID)
        )
      }
      .eraseToAnyPublisher()
  }
}
