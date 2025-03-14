//
//  RestorePushNotificationsUseCaseTests.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import XCTest
import Combine

final class RestorePushNotificationsUseCaseTests: XCTestCase {
  // MARK: - Properties
  
  private var fetchDateTimeUseCase: FetchDateTimeUseCaseMock!
  private var pushNotificationRepository: PushNotificationRepositoryMock!
  private var pushNotiRestorationStateRepository: PushNotiRestorationStateRepositoryMock!
  
  private var sut: DefaultRestorePushNotificationsUseCase!
  private var cancellables: Set<AnyCancellable>!
  
  // MARK: - Setup & Teardown
  
  override func setUp() {
    super.setUp()
    
    self.fetchDateTimeUseCase = FetchDateTimeUseCaseMock()
    self.pushNotificationRepository = PushNotificationRepositoryMock()
    self.pushNotiRestorationStateRepository = PushNotiRestorationStateRepositoryMock()
    
    self.sut = DefaultRestorePushNotificationsUseCase(
      fetchDateTimeUseCase: self.fetchDateTimeUseCase,
      pushNotificationRepository: self.pushNotificationRepository,
      pushNotiRestorationStateRepository: self.pushNotiRestorationStateRepository
    )
    
    self.cancellables = []
  }
  
  override func tearDown() {
    super.tearDown()
    
    self.fetchDateTimeUseCase = nil
    self.pushNotificationRepository = nil
    self.pushNotiRestorationStateRepository = nil
    self.sut = nil
    self.cancellables = nil
  }
  
  // MARK: - Helper Methods
  
  private func createProduct(
    id: String = UUID().uuidString,
    name: String,
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
  
  func test_복원할필요없을때_알림등록하지않음() {
    // Given
    let expectation = XCTestExpectation(description: "Should not restore notifications")
    
    let products = [
      createProduct(name: "제품1", expirationDate: Date().addingTimeInterval(86400))
    ]
    
    // shouldRestore가 false이면 알림 재등록 작업을 수행하지 않음
    self.pushNotiRestorationStateRepository.fetchRestoreStateResult = Just(
      PushNotiRestorationState(shouldRestore: false)
    )
    .setFailureType(to: Error.self)
    .eraseToAnyPublisher()
    
    // When
    sut.execute(products: products)
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
    // 알림 재등록 작업이 수행되지 않았는지 확인
    XCTAssertEqual(fetchDateTimeUseCase.executeCallCount, 0)
    XCTAssertEqual(pushNotificationRepository.scheduleNotificationCallCount, 0)
    XCTAssertEqual(pushNotiRestorationStateRepository.saveRestoreStateCallCount, 0)
  }
  
  func test_복원해야하지만_유효제품없음_알림등록하지않음() {
    // Given
    let expectation = XCTestExpectation(description: "Should restore but no valid products")
    
    // 현재 시간보다 과거의 만료일을 가진 제품들
    let pastDate = Date().addingTimeInterval(-86400) // 하루 전
    let products = [
      createProduct(name: "만료된 제품", expirationDate: pastDate)
    ]
    
    // shouldRestore가 true이면 알림 재등록 작업을 수행
    self.pushNotiRestorationStateRepository.fetchRestoreStateResult = Just(
      PushNotiRestorationState(shouldRestore: true)
    )
    .setFailureType(to: Error.self)
    .eraseToAnyPublisher()
    
    // DateTime 설정 (3일 전 알림)
    let dateTime = DateTime(date: 3, hour: 9, minute: 0)
    self.fetchDateTimeUseCase.executeResult = Just(dateTime)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // 상태 저장 성공 설정
    self.pushNotiRestorationStateRepository.saveRestoreStateResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // When
    sut.execute(products: products)
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
    // DateTime은 가져오지만
    XCTAssertEqual(fetchDateTimeUseCase.executeCallCount, 1)
    // 알림을 등록하지 않음
    XCTAssertEqual(pushNotificationRepository.scheduleNotificationCallCount, 0)
    // 상태를 false로 업데이트
    XCTAssertEqual(pushNotiRestorationStateRepository.saveRestoreStateCallCount, 1)
    XCTAssertEqual(pushNotiRestorationStateRepository.lastSavedRestorationState?.shouldRestore, false)
  }
  
  func test_복원필요하고_유효제품있음_알림등록성공() {
    // Given
    let expectation = XCTestExpectation(description: "Should restore with valid products")
    
    // 현재 시간보다 미래의 만료일을 가진 제품들
    let futureDate = Date().addingTimeInterval(86400 * 7) // 7일 후
    let products = [
      createProduct(name: "제품1", expirationDate: futureDate),
      createProduct(name: "제품2", expirationDate: futureDate.addingTimeInterval(86400)) // 8일 후
    ]
    
    // shouldRestore가 true이면 알림 재등록 작업을 수행
    self.pushNotiRestorationStateRepository.fetchRestoreStateResult = Just(
      PushNotiRestorationState(shouldRestore: true)
    )
    .setFailureType(to: Error.self)
    .eraseToAnyPublisher()
    
    // DateTime 설정 (3일 전 알림)
    let dateTime = DateTime(date: 3, hour: 9, minute: 0)
    self.fetchDateTimeUseCase.executeResult = Just(dateTime)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // 알림 등록 성공 설정
    self.pushNotificationRepository.scheduleNotificationResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // 상태 저장 성공 설정
    self.pushNotiRestorationStateRepository.saveRestoreStateResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // When
    sut.execute(products: products)
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
    // 2개의 제품에 대한 알림이 등록되어야 함
    XCTAssertEqual(pushNotificationRepository.scheduleNotificationCallCount, 2)
    // 상태를 false로 업데이트
    XCTAssertEqual(pushNotiRestorationStateRepository.saveRestoreStateCallCount, 1)
    XCTAssertEqual(pushNotiRestorationStateRepository.lastSavedRestorationState?.shouldRestore, false)
  }
  
  func test_복원시_DateTime조회실패_에러발생() {
    // Given
    let expectation = XCTestExpectation(description: "Should fail when DateTime repository fails")
    
    let products = [
      createProduct(name: "제품1", expirationDate: Date().addingTimeInterval(86400))
    ]
    
    // shouldRestore가 true이면 알림 재등록 작업을 수행
    self.pushNotiRestorationStateRepository.fetchRestoreStateResult = Just(
      PushNotiRestorationState(shouldRestore: true)
    )
    .setFailureType(to: Error.self)
    .eraseToAnyPublisher()
    
    // DateTime 가져오기 실패
    let expectedError = NSError(domain: "test", code: 1, userInfo: nil)
    self.fetchDateTimeUseCase.executeResult = Fail(error: expectedError)
      .eraseToAnyPublisher()
    
    // When
    sut.execute(products: products)
      .sink(
        receiveCompletion: { completion in
          if case .failure = completion {
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
    XCTAssertEqual(pushNotiRestorationStateRepository.saveRestoreStateCallCount, 0)
  }
  
  func test_복원시_알림등록실패_에러발생() {
    // Given
    let expectation = XCTestExpectation(description: "Should fail when push notification repository fails")
    
    let futureDate = Date().addingTimeInterval(86400 * 7) // 7일 후
    let products = [
      createProduct(name: "제품1", expirationDate: futureDate)
    ]
    
    // shouldRestore가 true이면 알림 재등록 작업을 수행
    self.pushNotiRestorationStateRepository.fetchRestoreStateResult = Just(
      PushNotiRestorationState(shouldRestore: true)
    )
    .setFailureType(to: Error.self)
    .eraseToAnyPublisher()
    
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
    sut.execute(products: products)
      .sink(
        receiveCompletion: { completion in
          if case .failure = completion {
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
    XCTAssertEqual(pushNotiRestorationStateRepository.saveRestoreStateCallCount, 0)
  }
  
  func test_복원시_상태저장실패_에러발생() {
    // Given
    let expectation = XCTestExpectation(description: "Should fail when state repository fails to save")
    
    let futureDate = Date().addingTimeInterval(86400 * 7) // 7일 후
    let products = [
      createProduct(name: "제품1", expirationDate: futureDate)
    ]
    
    // shouldRestore가 true이면 알림 재등록 작업을 수행
    self.pushNotiRestorationStateRepository.fetchRestoreStateResult = Just(
      PushNotiRestorationState(shouldRestore: true)
    )
    .setFailureType(to: Error.self)
    .eraseToAnyPublisher()
    
    // DateTime 설정 (3일 전 알림)
    let dateTime = DateTime(date: 3, hour: 9, minute: 0)
    self.fetchDateTimeUseCase.executeResult = Just(dateTime)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // 알림 등록 성공
    self.pushNotificationRepository.scheduleNotificationResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // 상태 저장 실패
    let expectedError = NSError(domain: "test", code: 3, userInfo: nil)
    self.pushNotiRestorationStateRepository.saveRestoreStateResult = Fail(error: expectedError)
      .eraseToAnyPublisher()
    
    // When
    sut.execute(products: products)
      .sink(
        receiveCompletion: { completion in
          if case .failure = completion {
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
    XCTAssertEqual(pushNotiRestorationStateRepository.saveRestoreStateCallCount, 1)
  }
  
  func test_제품목록이비었을때_정상완료() {
    // Given
    let expectation = XCTestExpectation(description: "Should complete with empty products")
    
    // shouldRestore가 true이면 알림 재등록 작업을 수행
    self.pushNotiRestorationStateRepository.fetchRestoreStateResult = Just(
      PushNotiRestorationState(shouldRestore: true)
    )
    .setFailureType(to: Error.self)
    .eraseToAnyPublisher()
    
    // DateTime 설정 (3일 전 알림)
    let dateTime = DateTime(date: 3, hour: 9, minute: 0)
    self.fetchDateTimeUseCase.executeResult = Just(dateTime)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // 상태 저장 성공 설정
    self.pushNotiRestorationStateRepository.saveRestoreStateResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // When
    sut.execute(products: [])
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
    XCTAssertEqual(pushNotificationRepository.scheduleNotificationCallCount, 0)
    XCTAssertEqual(pushNotiRestorationStateRepository.saveRestoreStateCallCount, 1)
  }
}
