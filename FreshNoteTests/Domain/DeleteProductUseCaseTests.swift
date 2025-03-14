//
//  DeleteProductUseCaseTests.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import XCTest
import Combine

final class DeleteProductUseCaseTests: XCTestCase {
  
  // MARK: - Properties
  
  private var imageRepository: ImageRepositoryMock!
  private var productRepository: ProductRepositoryMock!
  private var deletePushNotificationUseCase: DeletePushNotificationUseCaseMock!
  
  private var sut: DefaultDeleteProductUseCase!
  private var cancellables: Set<AnyCancellable>!
  
  // MARK: - Setup & Teardown
  
  override func setUp() {
    super.setUp()
    
    self.imageRepository = ImageRepositoryMock()
    self.productRepository = ProductRepositoryMock()
    self.deletePushNotificationUseCase = DeletePushNotificationUseCaseMock()
    
    self.sut = DefaultDeleteProductUseCase(
      imageRepository: self.imageRepository,
      productRepository: self.productRepository,
      deletePushNotificationUseCase: self.deletePushNotificationUseCase
    )
    
    self.cancellables = []
  }
  
  override func tearDown() {
    super.tearDown()
    
    self.imageRepository = nil
    self.productRepository = nil
    self.deletePushNotificationUseCase = nil
    self.sut = nil
    self.cancellables = nil
  }
  
  // MARK: - Helper Methods
  
  private func setupSuccess() {
    self.imageRepository.deleteImageResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    self.productRepository.deleteProductResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
  }
  
  // MARK: - Tests
  
  func test_execute_whenImageURLIsNil_shouldOnlyCallProductRepository() {
    // Given
    let expectation = XCTestExpectation(description: "Execute completes successfully")
    setupSuccess()
    
    let testDocumentID = DocumentID()
    
    // When
    self.sut.execute(did: testDocumentID, imageURL: nil)
      .sink(
        receiveCompletion: { completion in
          if case .finished = completion {
            expectation.fulfill()
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &self.cancellables)
    
    // Then
    wait(for: [expectation], timeout: 1.0)
    
    // imageRepository는 호출되지 않아야 함
    XCTAssertEqual(self.imageRepository.deleteImageCallCount, 0)
    // productRepository와 deletePushNotificationUseCase는 호출되어야 함
    XCTAssertEqual(self.productRepository.deleteProductCallCount, 1)
    XCTAssertEqual(self.deletePushNotificationUseCase.deleteNotificationCallCount, 1)
    
    // 올바른 파라미터가 전달되었는지 확인
    XCTAssertEqual(self.deletePushNotificationUseCase.lastDeletedProductID?.didString, testDocumentID.didString)
  }
  
  func test_execute_whenImageURLExists_shouldCallAllInSequence() {
    // Given
    let expectation = XCTestExpectation(description: "Execute completes successfully")
    setupSuccess()
    
    let testDocumentID = DocumentID()
    let testImageURL = URL(string: "https://example.com/image.jpg")!
    
    // When
    self.sut.execute(did: testDocumentID, imageURL: testImageURL)
      .sink(
        receiveCompletion: { completion in
          if case .finished = completion {
            expectation.fulfill()
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &self.cancellables)
    
    // Then
    wait(for: [expectation], timeout: 1.0)
    
    // 모든 메서드가 호출되어야 함
    XCTAssertEqual(self.imageRepository.deleteImageCallCount, 1)
    XCTAssertEqual(self.productRepository.deleteProductCallCount, 1)
    XCTAssertEqual(self.deletePushNotificationUseCase.deleteNotificationCallCount, 1)
    
    // 올바른 파라미터가 전달되었는지 확인
    XCTAssertEqual(self.deletePushNotificationUseCase.lastDeletedProductID?.didString, testDocumentID.didString)
  }
  
  func test_execute_whenImageURLIsNilAndProductRepositoryFails_shouldNotCallDeletePushNotification() {
    // Given
    let expectation = XCTestExpectation(description: "Execute fails with error")
    let expectedError = NSError(domain: "test", code: 1, userInfo: nil)
    
    // productRepository가 에러를 반환하도록 설정
    self.productRepository.deleteProductResult = Fail(error: expectedError).eraseToAnyPublisher()
    
    let testDocumentID = DocumentID()
    
    // When
    self.sut.execute(did: testDocumentID, imageURL: nil)
      .sink(
        receiveCompletion: { completion in
          if case .failure = completion {
            expectation.fulfill()
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &self.cancellables)
    
    // Then
    wait(for: [expectation], timeout: 1.0)
    
    // imageRepository는 호출되지 않아야 함
    XCTAssertEqual(self.imageRepository.deleteImageCallCount, 0)
    // productRepository는 호출되어야 함
    XCTAssertEqual(self.productRepository.deleteProductCallCount, 1)
    // deletePushNotificationUseCase는 호출되지 않아야 함 (flatMap 내부의 map 부분이 실행되지 않음)
    XCTAssertEqual(self.deletePushNotificationUseCase.deleteNotificationCallCount, 0)
  }
  
  func test_execute_whenImageURLExistsAndImageRepositoryFails_shouldNotCallProductRepository() {
    // Given
    let expectation = XCTestExpectation(description: "Execute fails with error")
    let expectedError = NSError(domain: "test", code: 1, userInfo: nil)
    
    // imageRepository가 에러를 반환하도록 설정
    self.imageRepository.deleteImageResult = Fail(error: expectedError).eraseToAnyPublisher()
    
    let testDocumentID = DocumentID()
    let testImageURL = URL(string: "https://example.com/image.jpg")!
    
    // When
    self.sut.execute(did: testDocumentID, imageURL: testImageURL)
      .sink(
        receiveCompletion: { completion in
          if case .failure = completion {
            expectation.fulfill()
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &self.cancellables)
    
    // Then
    wait(for: [expectation], timeout: 1.0)
    
    // imageRepository만 호출되어야 함
    XCTAssertEqual(self.imageRepository.deleteImageCallCount, 1)
    // productRepository와 deletePushNotificationUseCase는 호출되지 않아야 함
    XCTAssertEqual(self.productRepository.deleteProductCallCount, 0)
    XCTAssertEqual(self.deletePushNotificationUseCase.deleteNotificationCallCount, 0)
  }
  
  func test_execute_whenImageURLExistsAndProductRepositoryFails_shouldNotCallDeletePushNotification() {
    // Given
    let expectation = XCTestExpectation(description: "Execute fails with error")
    let expectedError = NSError(domain: "test", code: 1, userInfo: nil)
    
    // imageRepository는 성공, productRepository는 실패하도록 설정
    self.imageRepository.deleteImageResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    self.productRepository.deleteProductResult = Fail(error: expectedError).eraseToAnyPublisher()
    
    let testDocumentID = DocumentID()
    let testImageURL = URL(string: "https://example.com/image.jpg")!
    
    // When
    self.sut.execute(did: testDocumentID, imageURL: testImageURL)
      .sink(
        receiveCompletion: { completion in
          if case .failure = completion {
            expectation.fulfill()
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &self.cancellables)
    
    // Then
    wait(for: [expectation], timeout: 1.0)
    
    // imageRepository와 productRepository는 호출되어야 함
    XCTAssertEqual(self.imageRepository.deleteImageCallCount, 1)
    XCTAssertEqual(self.productRepository.deleteProductCallCount, 1)
    // deletePushNotificationUseCase는 호출되지 않아야 함
    XCTAssertEqual(self.deletePushNotificationUseCase.deleteNotificationCallCount, 0)
  }
  
  func test_execute_shouldPassCorrectParametersToRepositories() {
    // Given
    let expectation = XCTestExpectation(description: "Execute completes successfully")
    setupSuccess()
    
    let testDocumentID = DocumentID()
    let testImageURL = URL(string: "https://example.com/image.jpg")!
    
    // When
    self.sut.execute(did: testDocumentID, imageURL: testImageURL)
      .sink(
        receiveCompletion: { completion in
          if case .finished = completion {
            expectation.fulfill()
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &self.cancellables)
    
    // Then
    wait(for: [expectation], timeout: 1.0)
    
    // 올바른 파라미터가 전달되었는지 확인
    XCTAssertEqual(self.imageRepository.lastDeletedImageURL, testImageURL)
    XCTAssertEqual(self.productRepository.lastDeletedDidString, testDocumentID.didString)
    XCTAssertEqual(self.deletePushNotificationUseCase.lastDeletedProductID?.didString, testDocumentID.didString)
  }
} 
