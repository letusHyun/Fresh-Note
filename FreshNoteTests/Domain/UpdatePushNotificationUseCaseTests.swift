//
//  UpdatePushNotificationUseCaseTests.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import XCTest
import Combine

final class UpdatePushNotificationUseCaseTests: XCTestCase {
  // MARK: - Properties
  
  private var savePushNotificationUseCase: SavePushNotificationUseCaseMock!
  private var deletePushNotificationUseCase: DeletePushNotificationUseCaseMock!
  private var fetchProductUseCase: FetchProductUseCaseMock!
  
  // 단일 알림 업데이트용 UseCase (fetchProductUseCase 없음)
  private var sutSingle: DefaultUpdatePushNotificationUseCase!
  // 모든 알림 업데이트용 UseCase (fetchProductUseCase 포함)
  private var sutAll: DefaultUpdatePushNotificationUseCase!
  
  private var cancellables: Set<AnyCancellable>!
  
  // MARK: - Setup & Teardown
  
  override func setUp() {
    super.setUp()
    
    self.savePushNotificationUseCase = SavePushNotificationUseCaseMock()
    self.deletePushNotificationUseCase = DeletePushNotificationUseCaseMock()
    self.fetchProductUseCase = FetchProductUseCaseMock()
    
    // 단일 알림 업데이트용 UseCase 초기화
    self.sutSingle = DefaultUpdatePushNotificationUseCase(
      savePushNotificationUseCase: self.savePushNotificationUseCase,
      deletePushNotificationUseCase: self.deletePushNotificationUseCase
    )
    
    // 모든 알림 업데이트용 UseCase 초기화
    self.sutAll = DefaultUpdatePushNotificationUseCase(
      savePushNotificationUseCase: self.savePushNotificationUseCase,
      deletePushNotificationUseCase: self.deletePushNotificationUseCase,
      fetchProductUseCase: self.fetchProductUseCase
    )
    
    self.cancellables = []
    
    // 기본 결과값 설정
    self.savePushNotificationUseCase.saveNotificationResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    self.fetchProductUseCase.fetchProductsResult = Just([])
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
  }
  
  override func tearDown() {
    super.tearDown()
    
    self.savePushNotificationUseCase = nil
    self.deletePushNotificationUseCase = nil
    self.fetchProductUseCase = nil
    self.sutSingle = nil
    self.sutAll = nil
    self.cancellables = nil
  }
  
  // MARK: - Helper Methods
  
  private func createProduct(
    id: String = UUID().uuidString,
    name: String = "테스트 제품",
    expirationDate: Date = Date().addingTimeInterval(86400 * 7) // 7일 후
  ) -> Product {
    return Product(
      did: DocumentID(from: id) ?? DocumentID(),
      name: name,
      expirationDate: expirationDate,
      category: ProductCategory.건강,
      memo: nil,
      imageURL: nil,
      isPinned: false,
      creationDate: Date()
    )
  }
  
  // MARK: - Test Cases
  
  // 단일 제품 알림 업데이트 테스트
  func test_단일제품_알림업데이트_성공() {
    // Given
    let expectation = XCTestExpectation(description: "단일 제품 알림 업데이트 성공")
    let testProduct = createProduct()
    
    // When
    sutSingle.updateNotification(product: testProduct)
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
    XCTAssertEqual(deletePushNotificationUseCase.deleteNotificationCallCount, 1)
    XCTAssertEqual(deletePushNotificationUseCase.lastDeletedProductID?.didString, testProduct.did.didString)
    XCTAssertEqual(savePushNotificationUseCase.saveNotificationCallCount, 1)
    XCTAssertEqual(savePushNotificationUseCase.lastSavedProduct?.did.didString, testProduct.did.didString)
  }
  
  // 단일 제품 알림 업데이트 중 저장 실패 시 테스트
  func test_단일제품_알림저장실패_에러발생() {
    // Given
    let expectation = XCTestExpectation(description: "단일 제품 알림 저장 실패 시 에러 발생")
    let testProduct = createProduct()
    
    // 알림 저장 실패 설정
    let expectedError = NSError(domain: "test", code: 2, userInfo: nil)
    savePushNotificationUseCase.saveNotificationResult = Fail(error: expectedError)
      .eraseToAnyPublisher()
    
    // When
    sutSingle.updateNotification(product: testProduct)
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
    XCTAssertEqual(deletePushNotificationUseCase.deleteNotificationCallCount, 1)
    XCTAssertEqual(savePushNotificationUseCase.saveNotificationCallCount, 1)
  }
  
  // 모든 제품 알림 업데이트 테스트
  func test_전체제품_알림업데이트_성공() {
    // Given
    let expectation = XCTestExpectation(description: "모든 제품 알림 업데이트 성공")
    let testProducts = [
      createProduct(id: "1", name: "제품1"),
      createProduct(id: "2", name: "제품2"),
      createProduct(id: "3", name: "제품3")
    ]
    
    // fetchProductUseCase 응답 설정
    fetchProductUseCase.fetchProductsResult = Just(testProducts)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // When
    sutAll.updateNotifications()
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
    XCTAssertEqual(fetchProductUseCase.fetchProductsCallCount, 1)
    XCTAssertEqual(fetchProductUseCase.lastFetchSort, .default)
    XCTAssertEqual(deletePushNotificationUseCase.deleteAllNotificationsCallCount, 1)
    
    // testProducts의 모든 제품 ID가 삭제 요청에 포함되었는지 확인
    let expectedProductIDs = testProducts.map { $0.did }
    XCTAssertEqual(deletePushNotificationUseCase.lastDeletedProductIDs?.count, expectedProductIDs.count)
    
    // 각 제품에 대해 saveNotification이 호출되었는지 확인
    XCTAssertEqual(savePushNotificationUseCase.saveNotificationCallCount, testProducts.count)
  }
  
  // 모든 제품 알림 업데이트 중 제품 조회 실패 시 테스트
  func test_전체제품_제품조회실패_에러발생() {
    // Given
    let expectation = XCTestExpectation(description: "제품 조회 실패 시 에러 발생")
    
    // 제품 조회 실패 설정
    let expectedError = NSError(domain: "test", code: 3, userInfo: nil)
    fetchProductUseCase.fetchProductsResult = Fail(error: expectedError)
      .eraseToAnyPublisher()
    
    // When
    sutAll.updateNotifications()
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
    XCTAssertEqual(fetchProductUseCase.fetchProductsCallCount, 1)
    XCTAssertEqual(deletePushNotificationUseCase.deleteAllNotificationsCallCount, 0)
    XCTAssertEqual(savePushNotificationUseCase.saveNotificationCallCount, 0)
  }
  
  // 모든 제품 알림 업데이트 중 알림 저장 실패 시 테스트
  func test_전체제품_알림저장실패_에러발생() {
    // Given
    let expectation = XCTestExpectation(description: "알림 저장 실패 시 에러 발생")
    let testProducts = [
      createProduct(id: "1", name: "제품1"),
      createProduct(id: "2", name: "제품2")
    ]
    
    // fetchProductUseCase 응답 설정
    fetchProductUseCase.fetchProductsResult = Just(testProducts)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // 알림 저장 실패 설정
    let expectedError = NSError(domain: "test", code: 4, userInfo: nil)
    savePushNotificationUseCase.saveNotificationResult = Fail(error: expectedError)
      .eraseToAnyPublisher()
    
    // When
    sutAll.updateNotifications()
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
    XCTAssertEqual(fetchProductUseCase.fetchProductsCallCount, 1)
    XCTAssertEqual(deletePushNotificationUseCase.deleteAllNotificationsCallCount, 1)
    XCTAssertEqual(savePushNotificationUseCase.saveNotificationCallCount, 1) // 첫 번째 제품에서 실패
  }
  
  // 모든 제품 알림 업데이트 중 fetchProductUseCase가 nil일 때 테스트
  func test_전체제품_FetchProductUseCase없음_에러발생() {
    // Given
    let expectation = XCTestExpectation(description: "FetchProductUseCase 없을 때 에러 발생")
    
    // When
    sutSingle.updateNotifications() // fetchProductUseCase가 없는 인스턴스 사용
      .sink(
        receiveCompletion: { completion in
          if case let .failure(error) = completion {
            XCTAssertTrue(error is CommonError)
            if let commonError = error as? CommonError {
              XCTAssertEqual(commonError, CommonError.referenceError)
            }
            expectation.fulfill()
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &cancellables)
    
    // Then
    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(fetchProductUseCase.fetchProductsCallCount, 0)
    XCTAssertEqual(deletePushNotificationUseCase.deleteAllNotificationsCallCount, 0)
    XCTAssertEqual(savePushNotificationUseCase.saveNotificationCallCount, 0)
  }
} 