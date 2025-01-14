//
//  UpdateProductUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 12/5/24.
//

import Combine
import Foundation

enum UpdateProductUseCaseError: Error {
  case referenceError
}

protocol UpdateProductUseCase {
  func execute(product: Product, newImageData: Data?) -> AnyPublisher<Product, any Error>
}

final class DefaultUpdateProductUseCase: UpdateProductUseCase {
  private let productRepository: any ProductRepository
  private let imageRepository: any ImageRepository
  private let updatePushNotificationUseCase: any UpdatePushNotificationUseCase
  
  init(
    productRepository: any ProductRepository,
    imageRepository: any ImageRepository,
    updatePushNotificationUseCase: any UpdatePushNotificationUseCase
  ) {
    self.productRepository = productRepository
    self.imageRepository = imageRepository
    self.updatePushNotificationUseCase = updatePushNotificationUseCase
  }
  
  func execute(product: Product, newImageData: Data?) -> AnyPublisher<Product, any Error> {
    switch (product.imageURL, newImageData) {
    case (nil, nil): // 기존 이미지 x, 새 이미지 x
      return self.updateProductOnly(product: product)
    case (nil, let newImageData?): // 기존 이미지 x, 새 이미지 o
      return self.saveNewImageAndUpdateProduct(product: product, imageData: newImageData)
    case (let existingImageURL?, nil): // 기존 이미지 o, 새 이미지 x
      return self.deleteExistingImageAndUpdateProduct(product: product, existingImageURL: existingImageURL)
    case (let existingImageURL?, let newImageData?): // 기존 이미지 o, 새 이미지 o
      return self.replaceImageAndUpdateProduct(
        product: product,
        existingImageURL: existingImageURL,
        newImageData: newImageData
      )
    }
  }
}

// MARK: - Private Helpers
extension DefaultUpdateProductUseCase {
  private func makeNewProduct(product: Product, url: URL?) -> Product {
    return Product(
      did: product.did,
      name: product.name,
      expirationDate: product.expirationDate,
      category: product.category,
      memo: product.memo,
      imageURL: url,
      isPinned: product.isPinned,
      creationDate: product.creationDate
    )
  }
  
  private func updateProductOnly(product: Product) -> AnyPublisher<Product, any Error> {
    return self.productRepository
      .updateProduct(product: product)
      .flatMap { [weak self] product in
        guard let self else { return Empty<Product, any Error>().eraseToAnyPublisher() }
        
        return self.updatePushNotification(with: product)
      }
      .eraseToAnyPublisher()
  }
  
  private func saveNewImageAndUpdateProduct(
    product: Product,
    imageData: Data
  ) -> AnyPublisher<Product, any Error> {
    let newFileName = UUID().uuidString
    
    return self.imageRepository
      .saveImage(with: imageData, fileName: newFileName)
      .flatMap { [weak self] url in
        guard let self = self else {
          return Fail<Product, any Error>(error: UpdateProductUseCaseError.referenceError)
            .eraseToAnyPublisher()
        }
        
        let newProduct = self.makeNewProduct(product: product, url: url)
        return self.productRepository
          .updateProduct(product: newProduct)
          .flatMap { product in
            return self.updatePushNotification(with: product)
          }
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
  
  private func deleteExistingImageAndUpdateProduct(
    product: Product,
    existingImageURL: URL
  ) -> AnyPublisher<Product, any Error> {
    // 새 이미지가 없으면, 기존 이미지 제거하고 product 저장
    return self.imageRepository
      .deleteImage(with: existingImageURL)
      .flatMap { [weak self] in
        guard let self else {
          return Fail<Product, any Error>(error: UpdateProductUseCaseError.referenceError)
            .eraseToAnyPublisher()
        }
        let updatingProduct = self.makeNewProduct(product: product, url: nil)
        
        return self.productRepository
          .updateProduct(product: updatingProduct)
          .flatMap { product in
            return self.updatePushNotification(with: product)
          }
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
  
  private func replaceImageAndUpdateProduct(
    product: Product,
    existingImageURL: URL,
    newImageData: Data
  ) -> AnyPublisher<Product, any Error> {
    // 기존 이미지도 있고 새 이미지도 있는 경우
    // 기존 이미지 삭제 -> 새 이미지 저장 -> product 저장
    let newFileName = UUID().uuidString
    return self.imageRepository
      .deleteImage(with: existingImageURL)
      .flatMap { [weak self] in
        guard let self else {
          return Fail<URL, any Error>(error: UpdateProductUseCaseError.referenceError)
            .eraseToAnyPublisher()
        }
        
        return self.imageRepository
          .saveImage(with: newImageData, fileName: newFileName)
      }
      .flatMap { [weak self] url in
        guard let self else {
          return Fail<Product, any Error>(error: UpdateProductUseCaseError.referenceError)
            .eraseToAnyPublisher()
        }
        
        let newProduct = self.makeNewProduct(product: product, url: url)
        
        return self.productRepository
          .updateProduct(product: newProduct)
          .flatMap { product in
            return self.updatePushNotification(with: product)
          }
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
  
  private func updatePushNotification(with product: Product) -> AnyPublisher<Product, any Error> {
    return self.updatePushNotificationUseCase
      .updateNotification(product: product)
      .map { product }
      .eraseToAnyPublisher()
  }
}
