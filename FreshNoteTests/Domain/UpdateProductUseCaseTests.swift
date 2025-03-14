//
//  UpdateProductUseCaseTests.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import XCTest
import Combine

final class UpdateProductUseCaseTests: XCTestCase {
  // MARK: - Properties
  
  private var productRepository: ProductRepositoryMock!
  private var imageRepository: ImageRepositoryMock!
  private var updatePushNotificationUseCase: UpdatePushNotificationUseCaseMock!
  
  private var sut: DefaultUpdateProductUseCase!
  private var cancellables: Set<AnyCancellable>!
  
  // MARK: - Setup & Teardown
  
  override func setUp() {
    super.setUp()
    
    self.productRepository = ProductRepositoryMock()
    self.imageRepository = ImageRepositoryMock()
    self.updatePushNotificationUseCase = UpdatePushNotificationUseCaseMock()
    
    self.sut = DefaultUpdateProductUseCase(
      productRepository: self.productRepository,
      imageRepository: self.imageRepository,
      updatePushNotificationUseCase: self.updatePushNotificationUseCase
    )
    
    self.cancellables = []
    
    // 기본 결과값 설정
    self.productRepository.updateProductResult = Just(self.createProduct())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    self.productRepository.updateProductWithImageDeletionResult = Just(self.createProduct())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    self.imageRepository.saveImageResult = Just(URL(string: "https://example.com/image.jpg")!)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    self.imageRepository.deleteImageResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    self.updatePushNotificationUseCase.updateNotificationResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    self.updatePushNotificationUseCase.updateNotificationsResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
  }
  
  override func tearDown() {
    super.tearDown()
    
    self.productRepository = nil
    self.imageRepository = nil
    self.updatePushNotificationUseCase = nil
    self.sut = nil
    self.cancellables = nil
  }
  
  // MARK: - Helper Methods
  
  private func createProduct(
    id: String = UUID().uuidString,
    name: String = "테스트 제품",
    expirationDate: Date = Date().addingTimeInterval(86400 * 7), // 7일 후
    imageURL: URL? = nil,
    isPinned: Bool = false
  ) -> Product {
    return Product(
      did: DocumentID(from: id) ?? DocumentID(),
      name: name,
      expirationDate: expirationDate,
      category: ProductCategory.건강,
      memo: nil,
      imageURL: imageURL,
      isPinned: isPinned,
      creationDate: Date()
    )
  }
  
  // MARK: - Test Cases
  
  // 기존 이미지 없고, 새 이미지 없는 경우
  func test_이미지없이_제품정보만_업데이트() {
    // Given
    let expectation = XCTestExpectation(description: "제품 정보만 업데이트")
    let product = createProduct()
    
    // When
    sut.execute(product: product, newImageData: nil)
      .sink(
        receiveCompletion: { completion in
          if case .finished = completion {
            expectation.fulfill()
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &cancellables)
    
    // Then
    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(productRepository.updateProductCallCount, 1)
    XCTAssertEqual(imageRepository.saveImageCallCount, 0)
    XCTAssertEqual(imageRepository.deleteImageCallCount, 0)
    XCTAssertEqual(updatePushNotificationUseCase.updateNotificationCallCount, 1)
  }
  
  // 기존 이미지 없고, 새 이미지 있는 경우
  func test_새이미지_추가_및_제품정보_업데이트() {
    // Given
    let expectation = XCTestExpectation(description: "새 이미지 추가 및 제품 정보 업데이트")
    let product = createProduct()
    let newImageData = "test_image".data(using: .utf8)!
    
    // When
    sut.execute(product: product, newImageData: newImageData)
      .sink(
        receiveCompletion: { completion in
          if case .finished = completion {
            expectation.fulfill()
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &cancellables)
    
    // Then
    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(imageRepository.saveImageCallCount, 1)
    XCTAssertEqual(imageRepository.lastSavedImageData, newImageData)
    XCTAssertEqual(productRepository.updateProductCallCount, 1)
    XCTAssertEqual(updatePushNotificationUseCase.updateNotificationCallCount, 1)
  }
  
  // 기존 이미지 있고, 새 이미지 없고, 이미지 삭제하는 경우
  func test_기존이미지_삭제_및_제품정보_업데이트() {
    // Given
    let expectation = XCTestExpectation(description: "기존 이미지 삭제 및 제품 정보 업데이트")
    let existingImageURL = URL(string: "https://example.com/existing_image.jpg")!
    let product = createProduct(imageURL: existingImageURL)
    
    // 이미지 삭제 플래그 설정
    sut.setImageDeletionValue(true)
    
    // When
    sut.execute(product: product, newImageData: nil)
      .sink(
        receiveCompletion: { completion in
          if case .finished = completion {
            expectation.fulfill()
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &cancellables)
    
    // Then
    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(imageRepository.deleteImageCallCount, 1)
    XCTAssertEqual(imageRepository.lastDeletedImageURL, existingImageURL)
    XCTAssertEqual(productRepository.updateProductWithImageDeletionCallCount, 1)
    XCTAssertEqual(updatePushNotificationUseCase.updateNotificationCallCount, 1)
  }
  
  // 기존 이미지 있고, 새 이미지 없고, 이미지 유지하는 경우
  func test_기존이미지_유지_및_제품정보_업데이트() {
    // Given
    let expectation = XCTestExpectation(description: "기존 이미지 유지 및 제품 정보 업데이트")
    let existingImageURL = URL(string: "https://example.com/existing_image.jpg")!
    let product = createProduct(imageURL: existingImageURL)
    
    // 이미지 삭제 플래그 해제 (기본값이 false이므로 별도 설정 필요 없음)
    
    // When
    sut.execute(product: product, newImageData: nil)
      .sink(
        receiveCompletion: { completion in
          if case .finished = completion {
            expectation.fulfill()
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &cancellables)
    
    // Then
    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(imageRepository.deleteImageCallCount, 0)
    XCTAssertEqual(productRepository.updateProductCallCount, 1)
    XCTAssertEqual(updatePushNotificationUseCase.updateNotificationCallCount, 1)
  }
  
  // 기존 이미지 있고, 새 이미지 있는 경우
  func test_기존이미지_교체_및_제품정보_업데이트() {
    // Given
    let expectation = XCTestExpectation(description: "기존 이미지 교체 및 제품 정보 업데이트")
    let existingImageURL = URL(string: "https://example.com/existing_image.jpg")!
    let product = createProduct(imageURL: existingImageURL)
    let newImageData = "new_test_image".data(using: .utf8)!
    
    // When
    sut.execute(product: product, newImageData: newImageData)
      .sink(
        receiveCompletion: { completion in
          if case .finished = completion {
            expectation.fulfill()
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &cancellables)
    
    // Then
    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(imageRepository.deleteImageCallCount, 1)
    XCTAssertEqual(imageRepository.lastDeletedImageURL, existingImageURL)
    XCTAssertEqual(imageRepository.saveImageCallCount, 1)
    XCTAssertEqual(imageRepository.lastSavedImageData, newImageData)
    XCTAssertEqual(productRepository.updateProductCallCount, 1)
    XCTAssertEqual(updatePushNotificationUseCase.updateNotificationCallCount, 1)
  }
  
  // 이미지 저장 실패 시 에러 발생
  func test_이미지저장실패_에러발생() {
    // Given
    let expectation = XCTestExpectation(description: "이미지 저장 실패 시 에러 발생")
    let product = createProduct()
    let newImageData = "test_image".data(using: .utf8)!
    
    // 이미지 저장 실패 설정
    let expectedError = NSError(domain: "test", code: 1, userInfo: nil)
    imageRepository.saveImageResult = Fail(error: expectedError)
      .eraseToAnyPublisher()
    
    // When
    sut.execute(product: product, newImageData: newImageData)
      .sink(
        receiveCompletion: { completion in
          if case let .failure(error) = completion {
            XCTAssertEqual((error as NSError).code, expectedError.code)
            expectation.fulfill()
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &cancellables)
    
    // Then
    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(imageRepository.saveImageCallCount, 1)
    XCTAssertEqual(productRepository.updateProductCallCount, 0)
  }
  
  // 이미지 삭제 실패 시 에러 발생
  func test_이미지삭제실패_에러발생() {
    // Given
    let expectation = XCTestExpectation(description: "이미지 삭제 실패 시 에러 발생")
    let existingImageURL = URL(string: "https://example.com/existing_image.jpg")!
    let product = createProduct(imageURL: existingImageURL)
    
    // 이미지 삭제 플래그 설정
    sut.setImageDeletionValue(true)
    
    // 이미지 삭제 실패 설정
    let expectedError = NSError(domain: "test", code: 2, userInfo: nil)
    imageRepository.deleteImageResult = Fail(error: expectedError)
      .eraseToAnyPublisher()
    
    // When
    sut.execute(product: product, newImageData: nil)
      .sink(
        receiveCompletion: { completion in
          if case let .failure(error) = completion {
            XCTAssertEqual((error as NSError).code, expectedError.code)
            expectation.fulfill()
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &cancellables)
    
    // Then
    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(imageRepository.deleteImageCallCount, 1)
    XCTAssertEqual(productRepository.updateProductWithImageDeletionCallCount, 0)
  }
  
  // 제품 업데이트 실패 시 에러 발생
  func test_제품업데이트실패_에러발생() {
    // Given
    let expectation = XCTestExpectation(description: "제품 업데이트 실패 시 에러 발생")
    let product = createProduct()
    
    // 제품 업데이트 실패 설정
    let expectedError = NSError(domain: "test", code: 3, userInfo: nil)
    productRepository.updateProductResult = Fail(error: expectedError)
      .eraseToAnyPublisher()
    
    // When
    sut.execute(product: product, newImageData: nil)
      .sink(
        receiveCompletion: { completion in
          if case let .failure(error) = completion {
            XCTAssertEqual((error as NSError).code, expectedError.code)
            expectation.fulfill()
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &cancellables)
    
    // Then
    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(productRepository.updateProductCallCount, 1)
    XCTAssertEqual(updatePushNotificationUseCase.updateNotificationCallCount, 0)
  }
  
  // 알림 업데이트 실패 시 에러 발생
  func test_알림업데이트실패_에러발생() {
    // Given
    let expectation = XCTestExpectation(description: "알림 업데이트 실패 시 에러 발생")
    let product = createProduct()
    
    // 알림 업데이트 실패 설정
    let expectedError = NSError(domain: "test", code: 4, userInfo: nil)
    updatePushNotificationUseCase.updateNotificationResult = Fail(error: expectedError)
      .eraseToAnyPublisher()
    
    // When
    sut.execute(product: product, newImageData: nil)
      .sink(
        receiveCompletion: { completion in
          if case let .failure(error) = completion {
            XCTAssertEqual((error as NSError).code, expectedError.code)
            expectation.fulfill()
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &cancellables)
    
    // Then
    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(productRepository.updateProductCallCount, 1)
    XCTAssertEqual(updatePushNotificationUseCase.updateNotificationCallCount, 1)
  }
  
  // setImageDeletionValue 메서드 테스트
  func test_이미지삭제여부설정_정상동작() {
    // Given
    sut.setImageDeletionValue(false)
    let existingImageURL = URL(string: "https://example.com/existing_image.jpg")!
    let product = createProduct(imageURL: existingImageURL)
    let expectation1 = XCTestExpectation(description: "이미지 삭제 안 함")
    
    // When
    sut.execute(product: product, newImageData: nil)
      .sink(
        receiveCompletion: { completion in
          if case .finished = completion {
            expectation1.fulfill()
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &cancellables)
    
    // Then
    wait(for: [expectation1], timeout: 1.0)
    XCTAssertEqual(imageRepository.deleteImageCallCount, 0)
    XCTAssertEqual(productRepository.updateProductCallCount, 1)
    
    // Given - 이미지 삭제 플래그 설정
    sut.setImageDeletionValue(true)
    let expectation2 = XCTestExpectation(description: "이미지 삭제 함")
    
    // 이미지 레포지토리 호출 카운트 초기화
    imageRepository.resetCallCounts()
    productRepository.resetCallCounts() 
    updatePushNotificationUseCase.resetCallCounts()
    
    // When
    sut.execute(product: product, newImageData: nil)
      .sink(
        receiveCompletion: { completion in
          if case .finished = completion {
            expectation2.fulfill()
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &cancellables)
    
    // Then
    wait(for: [expectation2], timeout: 1.0)
    XCTAssertEqual(imageRepository.deleteImageCallCount, 1)
    XCTAssertEqual(productRepository.updateProductWithImageDeletionCallCount, 1)
  }
} 
