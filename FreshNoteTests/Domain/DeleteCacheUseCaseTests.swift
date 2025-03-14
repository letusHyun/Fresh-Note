//
//  DeleteCacheUseCaseTests.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import XCTest
import Combine

final class DeleteCacheUseCaseTests: XCTestCase {
  
  // MARK: - Properties
  
  private var productRepository: ProductRepositoryMock!
  private var dateTimeRepository: DateTimeRepositoryMock!
  private var productQueryRepository: ProductQueriesRepositoryMock!
  private var pushNotificationRepository: PushNotificationRepositoryMock!
  
  private var sut: DefaultDeleteCacheUseCase!
  private var cancellables: Set<AnyCancellable>!
  
  // MARK: - Setup & Teardown
  
  override func setUp() {
    super.setUp()
    
    self.productRepository = ProductRepositoryMock()
    self.dateTimeRepository = DateTimeRepositoryMock()
    self.productQueryRepository = ProductQueriesRepositoryMock()
    self.pushNotificationRepository = PushNotificationRepositoryMock()
    
    self.sut = DefaultDeleteCacheUseCase(
      productRepository: self.productRepository,
      dateTimeRepository: self.dateTimeRepository,
      productQueryRepository: self.productQueryRepository,
      pushNotificationRepository: self.pushNotificationRepository
    )
    
    self.cancellables = []
  }
  
  override func tearDown() {
    super.tearDown()
    
    self.productRepository = nil
    self.dateTimeRepository = nil
    self.productQueryRepository = nil
    self.pushNotificationRepository = nil
    self.sut = nil
    self.cancellables = nil
  }
  
  // MARK: - Helper Methods
  
  private func setupSuccess() {
    let documentIDs = [DocumentID(), DocumentID()]
    
    self.productRepository.deleteCachedProductsResult = Just(documentIDs)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    self.dateTimeRepository.deleteCachedDateTimeResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    self.productQueryRepository.deleteQueriesResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
  }
  
  // MARK: - Tests
  
  func test_execute_whenAllSuccess_shouldCallAllRepositoriesInOrder() {
    // Given
    let expectation = XCTestExpectation(description: "Execute completes successfully")
    setupSuccess()
    
    // When
    self.sut.execute()
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
    
    // 모든 Repository 메서드가 호출되었는지 확인
    XCTAssertEqual(self.productRepository.deleteCachedProductsCallCount, 1)
    XCTAssertEqual(self.dateTimeRepository.deleteCachedDateTimeCallCount, 1)
    XCTAssertEqual(self.productQueryRepository.deleteQueriesCallCount, 1)
    XCTAssertEqual(self.pushNotificationRepository.deleteNotificaionCallCount, 1)
  }
  
  func test_execute_whenProductRepositoryFails_shouldNotCallDownstreamRepositories() {
    // Given
    let expectation = XCTestExpectation(description: "Execute fails with error")
    let expectedError = NSError(domain: "test", code: 1, userInfo: nil)
    
    // productRepository가 에러를 반환하도록 설정
    self.productRepository.deleteCachedProductsResult = Fail(error: expectedError).eraseToAnyPublisher()
    
    // When
    self.sut.execute()
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
    
    // productRepository만 호출되고 다른 Repository는 호출되지 않아야 함
    XCTAssertEqual(self.productRepository.deleteCachedProductsCallCount, 1)
    XCTAssertEqual(self.dateTimeRepository.deleteCachedDateTimeCallCount, 0)
    XCTAssertEqual(self.productQueryRepository.deleteQueriesCallCount, 0)
    XCTAssertEqual(self.pushNotificationRepository.deleteNotificaionCallCount, 0)
  }
  
  func test_execute_whenDateTimeRepositoryFails_shouldNotCallDownstreamRepositories() {
    // Given
    let expectation = XCTestExpectation(description: "Execute fails with error")
    let expectedError = NSError(domain: "test", code: 1, userInfo: nil)
    
    // productRepository는 성공, dateTimeRepository는 실패하도록 설정
    let documentIDs = [DocumentID(), DocumentID()]
    self.productRepository.deleteCachedProductsResult = Just(documentIDs)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    self.dateTimeRepository.deleteCachedDateTimeResult = Fail(error: expectedError).eraseToAnyPublisher()
    
    // When
    self.sut.execute()
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
    
    // productRepository와 dateTimeRepository만 호출되고 다른 Repository는 호출되지 않아야 함
    XCTAssertEqual(self.productRepository.deleteCachedProductsCallCount, 1)
    XCTAssertEqual(self.dateTimeRepository.deleteCachedDateTimeCallCount, 1)
    XCTAssertEqual(self.productQueryRepository.deleteQueriesCallCount, 0)
    XCTAssertEqual(self.pushNotificationRepository.deleteNotificaionCallCount, 0)
  }
  
  func test_execute_whenProductQueryRepositoryFails_shouldNotCallPushNotificationRepository() {
    // Given
    let expectation = XCTestExpectation(description: "Execute fails with error")
    let expectedError = NSError(domain: "test", code: 1, userInfo: nil)
    
    // 앞의 두 Repository는 성공, productQueryRepository는 실패하도록 설정
    let documentIDs = [DocumentID(), DocumentID()]
    self.productRepository.deleteCachedProductsResult = Just(documentIDs)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    self.dateTimeRepository.deleteCachedDateTimeResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    self.productQueryRepository.deleteQueriesResult = Fail(error: expectedError).eraseToAnyPublisher()
    
    // When
    self.sut.execute()
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
    
    // 앞의 세 Repository만 호출되고 pushNotificationRepository는 호출되지 않아야 함
    XCTAssertEqual(self.productRepository.deleteCachedProductsCallCount, 1)
    XCTAssertEqual(self.dateTimeRepository.deleteCachedDateTimeCallCount, 1)
    XCTAssertEqual(self.productQueryRepository.deleteQueriesCallCount, 1)
    XCTAssertEqual(self.pushNotificationRepository.deleteNotificaionCallCount, 0)
  }
  
  func test_execute_shouldPassProductIDsToPushNotificationRepository() {
    // Given
    let expectation = XCTestExpectation(description: "Execute completes successfully")
    let testDocumentIDs = [DocumentID(), DocumentID()]
    
    // 모든 Repository가 성공하도록 설정
    self.productRepository.deleteCachedProductsResult = Just(testDocumentIDs)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    self.dateTimeRepository.deleteCachedDateTimeResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    self.productQueryRepository.deleteQueriesResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // When
    self.sut.execute()
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
    
    // pushNotificationRepository에 전달된 DocumentID가 productRepository가 반환한 것과 일치하는지 확인
    XCTAssertEqual(self.pushNotificationRepository.deletedNotificationIDs?.count, testDocumentIDs.count)
    for (index, id) in testDocumentIDs.enumerated() {
      XCTAssertEqual(self.pushNotificationRepository.deletedNotificationIDs?[index].didString, id.didString)
    }
  }
} 
