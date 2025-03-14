//
//  DeleteAccountUseCaseTests.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import XCTest
import Combine

final class DeleteAccountUseCaseTests: XCTestCase {
  
  // MARK: - Properties
  
  private var firebaseAuthRepository: FirebaseAuthRepositoryMock!
  private var firebaseDeletionRepository: FirebaseDeletionRepositoryMock!
  private var refreshTokenRepository: RefreshTokenRepositoryMock!
  private var pushNotiRestorationStateRepository: PushNotiRestorationStateRepositoryMock!
  private var pushNotificationRepository: PushNotificationRepositoryMock!
  private var deleteCacheRepository: DeleteCacheRepositoryMock!
  
  private var sut: DefaultDeleteAccountUseCase!
  private var cancellables: Set<AnyCancellable>!
  
  // MARK: - Setup & Teardown
  
  override func setUp() {
    super.setUp()
    
    self.firebaseAuthRepository = FirebaseAuthRepositoryMock()
    self.firebaseDeletionRepository = FirebaseDeletionRepositoryMock()
    self.refreshTokenRepository = RefreshTokenRepositoryMock()
    self.pushNotiRestorationStateRepository = PushNotiRestorationStateRepositoryMock()
    self.pushNotificationRepository = PushNotificationRepositoryMock()
    self.deleteCacheRepository = DeleteCacheRepositoryMock()
    
    self.sut = DefaultDeleteAccountUseCase(
      firebaseAuthRepository: self.firebaseAuthRepository,
      firebaseDeletionRepository: self.firebaseDeletionRepository,
      refreshTokenRepository: self.refreshTokenRepository,
      pushNotiRestorationStateRepository: self.pushNotiRestorationStateRepository,
      pushNotificationRepository: self.pushNotificationRepository,
      deleteCacheRepository: self.deleteCacheRepository
    )
    
    self.cancellables = []
  }
  
  override func tearDown() {
    super.tearDown()
    
    self.firebaseAuthRepository = nil
    self.firebaseDeletionRepository = nil
    self.refreshTokenRepository = nil
    self.pushNotiRestorationStateRepository = nil
    self.pushNotificationRepository = nil
    self.deleteCacheRepository = nil
    self.sut = nil
    self.cancellables = nil
  }
  
  // MARK: - Tests
  
  func test_execute_whenAllSuccess_shouldCallAllRepositoriesInOrder() {
    // Given
    let expectation = XCTestExpectation(description: "Execute completes successfully")
    
    // 모든 Repository 메서드가 성공적으로 동작하도록 설정
    self.firebaseDeletionRepository.deleteUserWithAllDataResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    self.firebaseAuthRepository.deleteAccountResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    
    let documentIDs = [DocumentID(), DocumentID()]
    self.deleteCacheRepository.deleteCachesResult = Just(documentIDs).setFailureType(to: Error.self).eraseToAnyPublisher()
    
    self.refreshTokenRepository.revokeRefreshTokenResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    self.refreshTokenRepository.deleteRefreshTokenResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    
    self.pushNotiRestorationStateRepository.saveRestoreStateResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    
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
    XCTAssertEqual(self.firebaseDeletionRepository.deleteUserWithAllDataCallCount, 1)
    XCTAssertEqual(self.firebaseAuthRepository.deleteAccountCallCount, 1)
    XCTAssertEqual(self.deleteCacheRepository.deleteCachesCallCount, 1)
    XCTAssertEqual(self.pushNotificationRepository.deleteNotificaionCallCount, 1)
    XCTAssertEqual(self.refreshTokenRepository.revokeRefreshTokenCallCount, 1)
    XCTAssertEqual(self.refreshTokenRepository.deleteRefreshTokenCallCount, 1)
    XCTAssertEqual(self.pushNotiRestorationStateRepository.saveRestoreStateCallCount, 1)
    
    // 올바른 파라미터가 전달되었는지 확인
    XCTAssertEqual(self.pushNotificationRepository.deletedNotificationIDs?.count, documentIDs.count)
  }
  
  func test_execute_whenFirebaseDeletionFails_shouldNotCallDownstreamPublishers() {
    // Given
    let expectation = XCTestExpectation(description: "Execute fails with error")
    let expectedError = NSError(domain: "test", code: 1, userInfo: nil)
    
    // firebaseDeletionRepository가 에러를 반환하도록 설정
    self.firebaseDeletionRepository.deleteUserWithAllDataResult = Fail(error: expectedError).eraseToAnyPublisher()
    
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
    
    // firebaseDeletionRepository만 호출되고 다른 Repository는 호출되지 않아야 함
    XCTAssertEqual(self.firebaseDeletionRepository.deleteUserWithAllDataCallCount, 1)
    XCTAssertEqual(self.firebaseAuthRepository.deleteAccountCallCount, 0)
    XCTAssertEqual(self.deleteCacheRepository.deleteCachesCallCount, 0)
    XCTAssertEqual(self.pushNotificationRepository.deleteNotificaionCallCount, 0)
    XCTAssertEqual(self.refreshTokenRepository.revokeRefreshTokenCallCount, 0)
    XCTAssertEqual(self.refreshTokenRepository.deleteRefreshTokenCallCount, 0)
    XCTAssertEqual(self.pushNotiRestorationStateRepository.saveRestoreStateCallCount, 0)
  }
  
  func test_execute_whenFirebaseAuthFails_shouldNotCallDownstreamPublishers() {
    // Given
    let expectation = XCTestExpectation(description: "Execute fails with error")
    let expectedError = NSError(domain: "test", code: 1, userInfo: nil)
    
    // firebaseDeletionRepository는 성공하지만 firebaseAuthRepository가 에러를 반환하도록 설정
    self.firebaseDeletionRepository.deleteUserWithAllDataResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    self.firebaseAuthRepository.deleteAccountResult = Fail(error: expectedError).eraseToAnyPublisher()
    
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
    
    // firebaseDeletionRepository와 firebaseAuthRepository만 호출되고 다른 Repository는 호출되지 않아야 함
    XCTAssertEqual(self.firebaseDeletionRepository.deleteUserWithAllDataCallCount, 1)
    XCTAssertEqual(self.firebaseAuthRepository.deleteAccountCallCount, 1)
    XCTAssertEqual(self.deleteCacheRepository.deleteCachesCallCount, 0)
    XCTAssertEqual(self.pushNotificationRepository.deleteNotificaionCallCount, 0)
    XCTAssertEqual(self.refreshTokenRepository.revokeRefreshTokenCallCount, 0)
    XCTAssertEqual(self.refreshTokenRepository.deleteRefreshTokenCallCount, 0)
    XCTAssertEqual(self.pushNotiRestorationStateRepository.saveRestoreStateCallCount, 0)
  }
  
  func test_execute_whenDeleteCacheFails_shouldNotCallDownstreamPublishers() {
    // Given
    let expectation = XCTestExpectation(description: "Execute fails with error")
    let expectedError = NSError(domain: "test", code: 1, userInfo: nil)
    
    // 앞의 두 Repository는 성공하지만 deleteCacheRepository가 에러를 반환하도록 설정
    self.firebaseDeletionRepository.deleteUserWithAllDataResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    self.firebaseAuthRepository.deleteAccountResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    self.deleteCacheRepository.deleteCachesResult = Fail(error: expectedError).eraseToAnyPublisher()
    
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
    
    // 앞의 세 Repository만 호출되고 다른 Repository는 호출되지 않아야 함
    XCTAssertEqual(self.firebaseDeletionRepository.deleteUserWithAllDataCallCount, 1)
    XCTAssertEqual(self.firebaseAuthRepository.deleteAccountCallCount, 1)
    XCTAssertEqual(self.deleteCacheRepository.deleteCachesCallCount, 1)
    XCTAssertEqual(self.pushNotificationRepository.deleteNotificaionCallCount, 0)
    XCTAssertEqual(self.refreshTokenRepository.revokeRefreshTokenCallCount, 0)
    XCTAssertEqual(self.refreshTokenRepository.deleteRefreshTokenCallCount, 0)
    XCTAssertEqual(self.pushNotiRestorationStateRepository.saveRestoreStateCallCount, 0)
  }
  
  func test_execute_whenRevokeRefreshTokenFails_shouldNotCallDownstreamPublishers() {
    // Given
    let expectation = XCTestExpectation(description: "Execute fails with error")
    let expectedError = NSError(domain: "test", code: 1, userInfo: nil)
    
    // 앞의 Repository들은 성공하지만 refreshTokenRepository.revokeRefreshToken이 에러를 반환하도록 설정
    self.firebaseDeletionRepository.deleteUserWithAllDataResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    self.firebaseAuthRepository.deleteAccountResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    
    let documentIDs = [DocumentID(), DocumentID()]
    self.deleteCacheRepository.deleteCachesResult = Just(documentIDs).setFailureType(to: Error.self).eraseToAnyPublisher()
    
    self.refreshTokenRepository.revokeRefreshTokenResult = Fail(error: expectedError).eraseToAnyPublisher()
    
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
    
    // 앞의 Repository들과 refreshTokenRepository.revokeRefreshToken만 호출되고 다른 메서드는 호출되지 않아야 함
    XCTAssertEqual(self.firebaseDeletionRepository.deleteUserWithAllDataCallCount, 1)
    XCTAssertEqual(self.firebaseAuthRepository.deleteAccountCallCount, 1)
    XCTAssertEqual(self.deleteCacheRepository.deleteCachesCallCount, 1)
    XCTAssertEqual(self.pushNotificationRepository.deleteNotificaionCallCount, 1)
    XCTAssertEqual(self.refreshTokenRepository.revokeRefreshTokenCallCount, 1)
    XCTAssertEqual(self.refreshTokenRepository.deleteRefreshTokenCallCount, 0)
    XCTAssertEqual(self.pushNotiRestorationStateRepository.saveRestoreStateCallCount, 0)
  }
  
  func test_execute_whenDeleteRefreshTokenFails_shouldNotCallDownstreamPublishers() {
    // Given
    let expectation = XCTestExpectation(description: "Execute fails with error")
    let expectedError = NSError(domain: "test", code: 1, userInfo: nil)
    
    // 앞의 Repository들은 성공하지만 refreshTokenRepository.deleteRefreshToken이 에러를 반환하도록 설정
    self.firebaseDeletionRepository.deleteUserWithAllDataResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    self.firebaseAuthRepository.deleteAccountResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    
    let documentIDs = [DocumentID(), DocumentID()]
    self.deleteCacheRepository.deleteCachesResult = Just(documentIDs).setFailureType(to: Error.self).eraseToAnyPublisher()
    
    self.refreshTokenRepository.revokeRefreshTokenResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    self.refreshTokenRepository.deleteRefreshTokenResult = Fail(error: expectedError).eraseToAnyPublisher()
    
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
    
    // 앞의 Repository들과 refreshTokenRepository.deleteRefreshToken까지 호출되고 마지막 메서드는 호출되지 않아야 함
    XCTAssertEqual(self.firebaseDeletionRepository.deleteUserWithAllDataCallCount, 1)
    XCTAssertEqual(self.firebaseAuthRepository.deleteAccountCallCount, 1)
    XCTAssertEqual(self.deleteCacheRepository.deleteCachesCallCount, 1)
    XCTAssertEqual(self.pushNotificationRepository.deleteNotificaionCallCount, 1)
    XCTAssertEqual(self.refreshTokenRepository.revokeRefreshTokenCallCount, 1)
    XCTAssertEqual(self.refreshTokenRepository.deleteRefreshTokenCallCount, 1)
    XCTAssertEqual(self.pushNotiRestorationStateRepository.saveRestoreStateCallCount, 0)
  }
  
  func test_execute_whenSaveRestoreStateFails_shouldFailWithError() {
    // Given
    let expectation = XCTestExpectation(description: "Execute fails with error")
    let expectedError = NSError(domain: "test", code: 1, userInfo: nil)
    
    // 모든 Repository는 성공하지만 마지막 pushNotiRestorationStateRepository.saveRestoreState가 에러를 반환하도록 설정
    self.firebaseDeletionRepository.deleteUserWithAllDataResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    self.firebaseAuthRepository.deleteAccountResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    
    let documentIDs = [DocumentID(), DocumentID()]
    self.deleteCacheRepository.deleteCachesResult = Just(documentIDs).setFailureType(to: Error.self).eraseToAnyPublisher()
    
    self.refreshTokenRepository.revokeRefreshTokenResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    self.refreshTokenRepository.deleteRefreshTokenResult = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    
    self.pushNotiRestorationStateRepository.saveRestoreStateResult = Fail(error: expectedError).eraseToAnyPublisher()
    
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
    
    // 모든 Repository 메서드가 호출되어야 함
    XCTAssertEqual(self.firebaseDeletionRepository.deleteUserWithAllDataCallCount, 1)
    XCTAssertEqual(self.firebaseAuthRepository.deleteAccountCallCount, 1)
    XCTAssertEqual(self.deleteCacheRepository.deleteCachesCallCount, 1)
    XCTAssertEqual(self.pushNotificationRepository.deleteNotificaionCallCount, 1)
    XCTAssertEqual(self.refreshTokenRepository.revokeRefreshTokenCallCount, 1)
    XCTAssertEqual(self.refreshTokenRepository.deleteRefreshTokenCallCount, 1)
    XCTAssertEqual(self.pushNotiRestorationStateRepository.saveRestoreStateCallCount, 1)
  }
}
