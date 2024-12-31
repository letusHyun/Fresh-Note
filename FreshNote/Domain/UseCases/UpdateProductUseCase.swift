//
//  UpdateProductUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 12/5/24.
//

import Combine
import Foundation

enum UpdateProductUseCaseError: Error {
  case failedToExecute
}

protocol UpdateProductUseCase {
  func execute(product: Product, newImageData: Data?) -> AnyPublisher<Product, any Error>
}

final class DefaultUpdateProductUseCase: UpdateProductUseCase {
  private let productRepository: any ProductRepository
  private let imageRepository: any ImageRepository
  
  init(
    productRepository: any ProductRepository,
    imageRepository: any ImageRepository
  ) {
    self.productRepository = productRepository
    self.imageRepository = imageRepository
  }
  
  func execute(product: Product, newImageData: Data?) -> AnyPublisher<Product, any Error> {
    guard let existingImageURL = product.imageURL else {
      // 기존 이미지가 없는 경우
      guard let newImageData = newImageData else {
        // 새 이미지도 없으면, product 저장
        return self.productRepository
          .updateProduct(product: product)
          .eraseToAnyPublisher()
      }
      
      // 새 이미지만 있으면, 이미지 저장 후 product 저장
      let newFileName = UUID().uuidString
      return self.imageRepository
        .saveImage(with: newImageData, fileName: newFileName)
        .flatMap { [weak self] url in
          guard let self = self else {
            return Fail<Product, any Error>(error: UpdateProductUseCaseError.failedToExecute)
              .eraseToAnyPublisher()
          }
          
          let newProduct = self.makeNewProduct(product: product, url: url)
          return self.productRepository
            .updateProduct(product: newProduct)
            .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    // 기존 이미지가 존재하는 경우
    guard let newImageData = newImageData else {
      // 새 이미지가 없으면, product 저장
      return self.productRepository
        .updateProduct(product: product)
        .eraseToAnyPublisher()
    }
    
    // 기존 이미지도 있고 새 이미지도 있는 경우
    // 기존 이미지 삭제 -> 새 이미지 저장 -> product 저장
    let newFileName = UUID().uuidString
    return self.imageRepository
      .deleteImage(with: existingImageURL)
      .flatMap { [weak self] in
        guard let self else {
          return Fail<URL, any Error>(error: UpdateProductUseCaseError.failedToExecute)
            .eraseToAnyPublisher()
        }
        
        return self.imageRepository
          .saveImage(with: newImageData, fileName: newFileName)
      }
      .flatMap { [weak self] url in
        guard let self else {
          return Fail<Product, any Error>(error: UpdateProductUseCaseError.failedToExecute)
            .eraseToAnyPublisher()
        }
        
        let newProduct = self.makeNewProduct(product: product, url: url)
        
        return self.productRepository
          .updateProduct(product: newProduct)
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
}

// MARK: - Private Helpers
extension DefaultUpdateProductUseCase {
  private func makeNewProduct(product: Product, url: URL) -> Product {
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
}
