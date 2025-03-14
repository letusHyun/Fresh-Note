//
//  SavePushNotificationUseCaseTests.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import XCTest
import Combine

final class SavePushNotificationUseCaseTests: XCTestCase {
  // MARK: - Properties
  
  private var fetchDateTimeUseCase: FetchDateTimeUseCaseMock!
  private var pushNotificationRepository: PushNotificationRepositoryMock!
  
  private var sut: DefaultSavePushNotificationUseCase!
  private var cancellables: Set<AnyCancellable>!
  
  // MARK: - Setup & Teardown
  
  override func setUp() {
    super.setUp()
    
    self.fetchDateTimeUseCase = FetchDateTimeUseCaseMock()
    self.pushNotificationRepository = PushNotificationRepositoryMock()
    
    self.sut = DefaultSavePushNotificationUseCase(
      fetchDateTimeUseCase: self.fetchDateTimeUseCase,
      pushNotificationRepository: self.pushNotificationRepository
    )
    
    self.cancellables = []
  }
  
  override func tearDown() {
    super.tearDown()
    
    self.fetchDateTimeUseCase = nil
    self.pushNotificationRepository = nil
    self.sut = nil
    self.cancellables = nil
  }
  
  // MARK: - Helper Methods
  
  private func createProduct(
    id: String = UUID().uuidString,
    name: String = "테스트 제품",
    expirationDate: Date,
    creationDate: Date = Date(),
    isPinned: Bool = false
  ) -> Product {
    return Product(
      did: DocumentID(from: id) ?? DocumentID(),
      name: name,
      expirationDate: expirationDate,
      category: ProductCategory.건강,
      memo: nil,
      imageURL: nil,
      isPinned: isPinned,
      creationDate: creationDate
    )
  }
  
  // MARK: - Test Cases
  
  func test_알림저장_성공() {
    // Given
    let expectation = XCTestExpectation(description: "알림 저장 성공")
    
    // 미래 날짜의 제품 생성
    let futureDate = Date().addingTimeInterval(86400 * 7) // 7일 후
    let product = createProduct(name: "테스트 제품", expirationDate: futureDate)
    
    // DateTime 설정 (3일 전 알림)
    let dateTime = DateTime(date: 3, hour: 9, minute: 0)
    self.fetchDateTimeUseCase.executeResult = Just(dateTime)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // 알림 등록 성공 설정
    self.pushNotificationRepository.scheduleNotificationResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // When
    sut.saveNotification(product: product)
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
    XCTAssertEqual(fetchDateTimeUseCase.executeCallCount, 1)
    XCTAssertEqual(pushNotificationRepository.scheduleNotificationCallCount, 1)
    
    // 요청 엔티티의 날짜 검증
    // 날짜 계산: 만료일로부터 dateTime.date일 전, 시간은 dateTime.hour와 dateTime.minute로 설정됨
    let calendar = Calendar.current
    let expectedNotificationDate = calendar.date(byAdding: .day, value: -dateTime.date, to: product.expirationDate)
    
    // 시간 설정을 위한 컴포넌트 생성
    guard let expectedDate = expectedNotificationDate else {
      XCTFail("알림 날짜 계산 실패")
      return
    }
    
    var components = calendar.dateComponents([.year, .month, .day], from: expectedDate)
    components.hour = dateTime.hour
    components.minute = dateTime.minute
    
    let expectedDateTime = calendar.date(from: components)
    XCTAssertNotNil(expectedDateTime)
    guard let requestDate = pushNotificationRepository.lastRequestEntity?.date,
          let expectedDate = expectedDateTime else {
      XCTFail("알림 날짜가 nil입니다")
      return
    }
    
    XCTAssertEqual(
      requestDate.timeIntervalSince1970,
      expectedDate.timeIntervalSince1970,
      accuracy: 1.0
    )
    
    // 바디 검증
    let expectedBody = NotificationHelper.makeBody(
      productName: product.name,
      remainingDay: dateTime.date
    )
    XCTAssertEqual(pushNotificationRepository.lastRequestEntity?.body, expectedBody)
  }
  
  func test_알림날짜가_현재보다_과거인경우_알림등록하지않음() {
    // Given
    let expectation = XCTestExpectation(description: "과거 알림 날짜일 경우 알림 등록 생략")
    
    // 현재 시간에서 2일 후의 만료일을 가진 제품 (알림은 3일 전이므로 과거)
    let expirationDate = Date().addingTimeInterval(86400 * 2) // 2일 후
    let product = createProduct(expirationDate: expirationDate)
    
    // DateTime 설정 (3일 전 알림)
    let dateTime = DateTime(date: 3, hour: 9, minute: 0)
    self.fetchDateTimeUseCase.executeResult = Just(dateTime)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // When
    sut.saveNotification(product: product)
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
    XCTAssertEqual(fetchDateTimeUseCase.executeCallCount, 1)
    // 알림이 등록되지 않아야 함
    XCTAssertEqual(pushNotificationRepository.scheduleNotificationCallCount, 0)
  }
  
  func test_DateTime조회실패_에러발생() {
    // Given
    let expectation = XCTestExpectation(description: "DateTime 조회 실패 시 에러 발생")
    
    let futureDate = Date().addingTimeInterval(86400 * 7) // 7일 후
    let product = createProduct(expirationDate: futureDate)
    
    // DateTime 가져오기 실패
    let expectedError = NSError(domain: "test", code: 1, userInfo: nil)
    self.fetchDateTimeUseCase.executeResult = Fail(error: expectedError)
      .eraseToAnyPublisher()
    
    // When
    sut.saveNotification(product: product)
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
    XCTAssertEqual(fetchDateTimeUseCase.executeCallCount, 1)
    XCTAssertEqual(pushNotificationRepository.scheduleNotificationCallCount, 0)
  }
  
  func test_알림등록실패_에러발생() {
    // Given
    let expectation = XCTestExpectation(description: "알림 등록 실패 시 에러 발생")
    
    let futureDate = Date().addingTimeInterval(86400 * 7) // 7일 후
    let product = createProduct(expirationDate: futureDate)
    
    // DateTime 설정 (3일 전 알림)
    let dateTime = DateTime(date: 3, hour: 9, minute: 0)
    self.fetchDateTimeUseCase.executeResult = Just(dateTime)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // 알림 등록 실패
    let expectedError = NSError(domain: "test", code: 2, userInfo: nil)
    self.pushNotificationRepository.scheduleNotificationResult = Fail(error: expectedError)
      .eraseToAnyPublisher()
    
    // When
    sut.saveNotification(product: product)
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
    XCTAssertEqual(fetchDateTimeUseCase.executeCallCount, 1)
    XCTAssertEqual(pushNotificationRepository.scheduleNotificationCallCount, 1)
  }
} 
