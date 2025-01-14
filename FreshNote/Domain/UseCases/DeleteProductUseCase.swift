//
//  DeleteProductUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 12/3/24.
//

import Combine
import Foundation

protocol DeleteProductUseCase {
  func execute(did: DocumentID, imageURL: URL?) -> AnyPublisher<Void, any Error>
}

final class DefaultDeleteProductUseCase: DeleteProductUseCase {
  private let imageRepository: any ImageRepository
  private let productRepository: any ProductRepository
  private let deletePushNotificationUseCase: any DeletePushNotificationUseCase
  
  init(
    imageRepository: any ImageRepository,
    productRepository: any ProductRepository,
    deletePushNotificationUseCase: any DeletePushNotificationUseCase
  ) {
    self.imageRepository = imageRepository
    self.productRepository = productRepository
    self.deletePushNotificationUseCase = deletePushNotificationUseCase
  }
  
  func execute(did: DocumentID, imageURL: URL?) -> AnyPublisher<Void, any Error> {
    guard let imageURL = imageURL else {
      return productRepository
        .deleteProduct(didString: did.didString)
        .map { [weak self] in
          self?.deletePushNotificationUseCase
            .deleteNotification(productID: did)
          return
        }
        .eraseToAnyPublisher()
    }
    
    return self.imageRepository.deleteImage(with: imageURL)
      .flatMap { [productRepository] _ in
        return productRepository
          .deleteProduct(didString: did.didString)
          .map { [weak self] in
            self?.deletePushNotificationUseCase
              .deleteNotification(productID: did)
            return
          }
      }
      .eraseToAnyPublisher()
  }
}
