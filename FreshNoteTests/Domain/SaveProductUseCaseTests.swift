//
//  SaveProductUseCaseTests.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import XCTest
import Combine

final class SaveProductUseCaseTests: XCTestCase {
  
  // MARK: - Properties
  
  private var productRepository: ProductRepositoryMock!
  private var imageRepository: ImageRepositoryMock!
  private var savePushNotificationUseCase: SavePushNotificationUseCaseMock!
  
  private var sut: DefaultSaveProductUseCase!
  private var cancellables: Set<AnyCancellable>!
  
  // MARK: - Setup & Teardown
  
  override func setUp() {
    super.setUp()
    
    self.productRepository = ProductRepositoryMock()
    self.imageRepository = ImageRepositoryMock()
    self.savePushNotificationUseCase = SavePushNotificationUseCaseMock()
    
    self.sut = DefaultSaveProductUseCase(
      productRepository: self.productRepository,
      imageRepository: self.imageRepository,
      savePushNotificationUseCase: self.savePushNotificationUseCase
    )
    
    self.cancellables = []
  }
  
  override func tearDown() {
    super.tearDown()
    
    self.productRepository = nil
    self.imageRepository = nil
    self.savePushNotificationUseCase = nil
    self.sut = nil
    self.cancellables = nil
  }
  
  // MARK: - Helper Methods
  
  private func createRequestValue(
    name: String = "테스트 제품",
    expirationDate: Date = Date().addingTimeInterval(86400 * 7), // 일주일 뒤
    category: String = ProductCategory.건강.rawValue,
    memo: String? = "테스트 메모",
    imageData: Data? = nil,
    isPinned: Bool = false
  ) -> SaveProductUseCaseRequestValue {
    return SaveProductUseCaseRequestValue(
      name: name,
      expirationDate: expirationDate,
      category: category,
      memo: memo,
      imageData: imageData,
      isPinned: isPinned
    )
  }
  
  // MARK: - Test Cases
  
  /// 이미지 없이 제품 저장 성공 테스트
  func test_이미지없이_제품저장_성공() {
    // Given
    let expectation = XCTestExpectation(description: "제품 저장 성공")
    let requestValue = createRequestValue(imageData: nil)
    
    // 제품 저장 및 푸시 알림 저장 성공 설정
    self.productRepository.saveProductResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    self.savePushNotificationUseCase.saveNotificationResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    
    // When
    self.sut.execute(requestValue: requestValue)
      .sink(
        receiveCompletion: { completion in
          if case .finished = completion {
            expectation.fulfill()
          }
        },
        receiveValue: { product in
          // Then
          XCTAssertEqual(product.name, requestValue.name)
          XCTAssertEqual(product.category, ProductCategory.건강)
          XCTAssertEqual(product.memo, requestValue.memo)
          XCTAssertNil(product.imageURL)
          XCTAssertEqual(product.isPinned, requestValue.isPinned)
        }
      )
      .store(in: &self.cancellables)
    
    wait(for: [expectation], timeout: 1.0)
    
    // 호출 확인
    XCTAssertEqual(self.productRepository.saveProductCallCount, 1)
    XCTAssertEqual(self.imageRepository.saveImageCallCount, 0)
    XCTAssertEqual(self.savePushNotificationUseCase.saveNotificationCallCount, 1)
  }
  
  /// 이미지와 함께 제품 저장 성공 테스트
  func test_이미지와함께_제품저장_성공() {
    // Given
    let expectation = XCTestExpectation(description: "이미지와 함께 제품 저장 성공")
    
    let testImageData = "test-image".data(using: .utf8)!
    let requestValue = createRequestValue(imageData: testImageData)
    let testImageURL = URL(string: "https://example.com/image.jpg")!
    
    // 성공 결과 설정
    self.imageRepository.saveImageResult = Just(testImageURL).setFailureType(to: Error.self).eraseToAnyPublisher()
    self.productRepository.saveProductResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    self.savePushNotificationUseCase.saveNotificationResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    
    // When
    self.sut.execute(requestValue: requestValue)
      .sink(
        receiveCompletion: { completion in
          if case .finished = completion {
            expectation.fulfill()
          }
        },
        receiveValue: { product in
          // Then
          XCTAssertEqual(product.name, requestValue.name)
          XCTAssertEqual(product.category, ProductCategory.건강)
          XCTAssertEqual(product.memo, requestValue.memo)
          XCTAssertEqual(product.imageURL, testImageURL)
          XCTAssertEqual(product.isPinned, requestValue.isPinned)
        }
      )
      .store(in: &self.cancellables)
    
    wait(for: [expectation], timeout: 1.0)
    
    // 호출 및 데이터 확인
    XCTAssertEqual(self.imageRepository.saveImageCallCount, 1)
    XCTAssertEqual(self.imageRepository.lastSavedImageData, testImageData)
    XCTAssertEqual(self.productRepository.saveProductCallCount, 1)
    
    XCTAssertNotNil(self.productRepository.lastSavedProduct)
    if let lastSavedProduct = self.productRepository.lastSavedProduct {
      XCTAssertEqual(lastSavedProduct.imageURL, testImageURL)
    }
    
    XCTAssertEqual(self.savePushNotificationUseCase.saveNotificationCallCount, 1)
  }
  
  /// 이미지 저장 실패 시 에러 발생 테스트
  func test_이미지저장_실패시_에러발생() {
    // Given
    let expectation = XCTestExpectation(description: "이미지 저장 실패")
    
    let testImageData = "test-image".data(using: .utf8)!
    let requestValue = createRequestValue(imageData: testImageData)
    
    // 이미지 저장 실패 설정
    let expectedError = NSError(domain: "test", code: 1, userInfo: nil)
    self.imageRepository.saveImageResult = Fail(error: expectedError).eraseToAnyPublisher()
    
    // When
    self.sut.execute(requestValue: requestValue)
      .sink(
        receiveCompletion: { completion in
          if case .failure = completion {
            expectation.fulfill()
          }
        },
        receiveValue: { _ in
          XCTFail("제품 저장이 성공하면 안됩니다")
        }
      )
      .store(in: &self.cancellables)
    
    wait(for: [expectation], timeout: 1.0)
    
    // 호출 확인
    XCTAssertEqual(self.imageRepository.saveImageCallCount, 1)
    XCTAssertEqual(self.productRepository.saveProductCallCount, 0)
    XCTAssertEqual(self.savePushNotificationUseCase.saveNotificationCallCount, 0)
  }
  
  /// 제품 저장 실패 시 이미지 롤백 및 에러 발생 테스트
  func test_제품저장_실패시_이미지롤백_및_에러발생() {
    // Given
    let expectation = XCTestExpectation(description: "제품 저장 실패 시 이미지 롤백")
    
    let testImageData = "test-image".data(using: .utf8)!
    let requestValue = createRequestValue(imageData: testImageData)
    let testImageURL = URL(string: "https://example.com/image.jpg")!
    
    // 이미지 저장 성공, 제품 저장 실패, 이미지 삭제 성공 설정
    self.imageRepository.saveImageResult = Just(testImageURL).setFailureType(to: Error.self).eraseToAnyPublisher()
    self.productRepository.saveProductResult = Fail(error: NSError(domain: "test", code: 2, userInfo: nil)).eraseToAnyPublisher()
    self.imageRepository.deleteImageResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    
    // When
    self.sut.execute(requestValue: requestValue)
      .sink(
        receiveCompletion: { completion in
          if case .failure(let error) = completion,
             let saveError = error as? SaveProductUseCaseError,
             saveError == SaveProductUseCaseError.failToSaveProduct {
            expectation.fulfill()
          }
        },
        receiveValue: { _ in
          XCTFail("제품 저장이 성공하면 안됩니다")
        }
      )
      .store(in: &self.cancellables)
    
    wait(for: [expectation], timeout: 1.0)
    
    // 호출 및 롤백 확인
    XCTAssertEqual(self.imageRepository.saveImageCallCount, 1)
    XCTAssertEqual(self.productRepository.saveProductCallCount, 1)
    XCTAssertEqual(self.imageRepository.deleteImageCallCount, 1)
    XCTAssertEqual(self.imageRepository.lastDeletedImageURL, testImageURL)
    XCTAssertEqual(self.savePushNotificationUseCase.saveNotificationCallCount, 0)
  }
  
  /// 푸시 알림 저장 실패 시 에러 발생 테스트
  func test_푸시알림저장_실패시_에러발생() {
    // Given
    let expectation = XCTestExpectation(description: "푸시 알림 저장 실패")
    
    let requestValue = createRequestValue(imageData: nil)
    
    // 제품 저장 성공, 푸시 알림 저장 실패 설정
    self.productRepository.saveProductResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    self.savePushNotificationUseCase.saveNotificationResult = Fail(error: NSError(domain: "test", code: 3, userInfo: nil)).eraseToAnyPublisher()
    
    // When
    self.sut.execute(requestValue: requestValue)
      .sink(
        receiveCompletion: { completion in
          if case .failure = completion {
            expectation.fulfill()
          }
        },
        receiveValue: { _ in
          XCTFail("제품 저장이 성공하면 안됩니다")
        }
      )
      .store(in: &self.cancellables)
    
    wait(for: [expectation], timeout: 1.0)
    
    // 호출 확인
    XCTAssertEqual(self.productRepository.saveProductCallCount, 1)
    XCTAssertEqual(self.savePushNotificationUseCase.saveNotificationCallCount, 1)
  }
  
  /// 잘못된 카테고리 값이 기본값으로 설정되는지 테스트
  func test_카테고리_잘못된값_기본값으로_설정() {
    // Given
    let expectation = XCTestExpectation(description: "잘못된 카테고리를 기본값으로 설정")
    
    let invalidCategory = "존재하지않는카테고리"
    let requestValue = createRequestValue(category: invalidCategory)
    
    // 제품 저장 및 푸시 알림 저장 성공 설정
    self.productRepository.saveProductResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    self.savePushNotificationUseCase.saveNotificationResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    
    // When
    self.sut.execute(requestValue: requestValue)
      .sink(
        receiveCompletion: { completion in
          if case .finished = completion {
            expectation.fulfill()
          }
        },
        receiveValue: { product in
          // Then
          XCTAssertEqual(product.category, ProductCategory.건강) // 기본값은 건강
        }
      )
      .store(in: &self.cancellables)
    
    wait(for: [expectation], timeout: 1.0)
    
    // 카테고리 기본값 확인
    XCTAssertEqual(self.productRepository.saveProductCallCount, 1)
    XCTAssertNotNil(self.productRepository.lastSavedProduct)
    if let lastSavedProduct = self.productRepository.lastSavedProduct {
      XCTAssertEqual(lastSavedProduct.category, ProductCategory.건강)
    }
  }
}
