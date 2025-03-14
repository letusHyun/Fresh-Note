//
//  SaveProductUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 11/27/24.
//

import Combine
import Foundation

enum SaveProductUseCaseError: Error {
  case failToSaveProduct
  
  var errorDescription: String? {
    switch self {
    case .failToSaveProduct:
      return "제품 저장에 실패했습니다."
    }
  }
}

protocol SaveProductUseCase {
  func execute(requestValue: SaveProductUseCaseRequestValue) -> AnyPublisher<Product, any Error>
}

final class DefaultSaveProductUseCase: SaveProductUseCase {
  private let productRepository: any ProductRepository
  private let imageRepository: any ImageRepository
  private let savePushNotificationUseCase: any SavePushNotificationUseCase
  
  private var subscriptions: Set<AnyCancellable> = []
  
  init(
    productRepository: any ProductRepository,
    imageRepository: any ImageRepository,
    savePushNotificationUseCase: any SavePushNotificationUseCase
  ) {
    self.productRepository = productRepository
    self.imageRepository = imageRepository
    self.savePushNotificationUseCase = savePushNotificationUseCase
  }
  
  func execute(requestValue: SaveProductUseCaseRequestValue) -> AnyPublisher<Product, any Error> {
    // 업데이트 된 경우
    // 이미지가 존재하지 않는 경우
    guard let imageData = requestValue.imageData else {
      let product = self.makeProduct(from: requestValue, url: nil)
      
      return self.productRepository.saveProduct(product: product)
        .flatMap { [weak self] in
          guard let self else {
            return Fail<Product, any Error>(error: CommonError.referenceError).eraseToAnyPublisher()
          }
          
          return self.savePushNotificationUseCase
            .saveNotification(product: product)
            .map { return product }
            .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    // 이미지가 존재하는 경우
    let fileName = UUID().uuidString
    return self.imageRepository
      .saveImage(with: imageData, fileName: fileName)
      .flatMap { [weak self] url in
        guard let self = self else {
          return Fail<Product, any Error>(error: CommonError.referenceError).eraseToAnyPublisher()
        }
        let product = self.makeProduct(from: requestValue, url: url)
        
        return self.productRepository
          .saveProduct(product: product)
          .retry(2)
          .catch { _ in // 실패한 경우 firebase storage에서 이미지 제거 (rollback)
            return self.imageRepository.deleteImage(with: url)
              .flatMap {
                return Fail(error: SaveProductUseCaseError.failToSaveProduct).eraseToAnyPublisher()
              }
          }
          .flatMap { // 푸시 알림 저장
            return self.savePushNotificationUseCase
              .saveNotification(product: product)
              .map { return product }
              .eraseToAnyPublisher()
          }
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
}

// MARK: - Private Helpers
extension DefaultSaveProductUseCase {
  private func makeProduct(from requestValue: SaveProductUseCaseRequestValue, url: URL?) -> Product {
    let dateFormatManager = DateFormatManager()
    
    return Product(
      did: DocumentID(),
      name: requestValue.name,
      expirationDate: requestValue.expirationDate,
      category: ProductCategory(rawValue: requestValue.category) ?? .건강,
      memo: requestValue.memo,
      imageURL: url,
      isPinned: requestValue.isPinned,
      creationDate: dateFormatManager.makeCurrentDate()
    )
  }
}

// MARK: - Request Value
struct SaveProductUseCaseRequestValue {
  let name: String
  let expirationDate: Date
  let category: String
  let memo: String?
  let imageData: Data?
  let isPinned: Bool
}
