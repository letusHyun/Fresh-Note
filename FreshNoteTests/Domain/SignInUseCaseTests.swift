//
//  SignInUseCaseTests.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import XCTest
import Combine

final class SignInUseCaseTests: XCTestCase {
  // MARK: - Properties
  
  private var firebaseAuthRepository: FirebaseAuthRepositoryMock!
  private var refreshTokenRepository: RefreshTokenRepositoryMock!
  private var pushNotiRestorationStateRepository: PushNotiRestorationStateRepositoryMock!
  
  private var sut: DefaultSignInUseCase!
  private var cancellables: Set<AnyCancellable>!
  
  // MARK: - Setup & Teardown
  
  override func setUp() {
    super.setUp()
    
    self.firebaseAuthRepository = FirebaseAuthRepositoryMock()
    self.refreshTokenRepository = RefreshTokenRepositoryMock()
    self.pushNotiRestorationStateRepository = PushNotiRestorationStateRepositoryMock()
    
    // 기본 결과값 설정
    self.refreshTokenRepository.revokeRefreshTokenResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    self.sut = DefaultSignInUseCase(
      firebaseAuthRepository: self.firebaseAuthRepository,
      refreshTokenRepository: self.refreshTokenRepository,
      pushNotiRestorationStateRepository: self.pushNotiRestorationStateRepository
    )
    
    self.cancellables = []
  }
  
  override func tearDown() {
    super.tearDown()
    
    self.firebaseAuthRepository = nil
    self.refreshTokenRepository = nil
    self.pushNotiRestorationStateRepository = nil
    self.sut = nil
    self.cancellables = nil
  }
  
  // MARK: - Helper Methods
  
  private func createAppleAuthProvider(
    idToken: String = "test_id_token",
    nonce: String = "test_nonce",
    fullName: PersonNameComponents? = PersonNameComponents(givenName: "Test", familyName: "User"),
    authorizationCode: Data = "test_authorization_code".data(using: .utf8)!
  ) -> AuthenticationProvider {
    return .apple(
      idToken: idToken,
      nonce: nonce,
      fullName: fullName,
      authorizationCode: authorizationCode
    )
  }
  
  // MARK: - Test Cases
  
  func test_최초로그인_성공() {
    // Given
    let expectation = XCTestExpectation(description: "최초 로그인 성공")
    
    // 인증 성공 설정
    self.firebaseAuthRepository.signInResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // refresh token이 존재하지 않음 설정
    self.refreshTokenRepository.isSavedRefreshTokenResult = Just(false)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // pushNoti 알림 복원 상태 저장 성공 설정
    self.pushNotiRestorationStateRepository.saveRestoreStateResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // refresh token 발급 성공 설정
    let testTokenString = "test_refresh_token"
    let testRefreshToken = RefreshToken(tokenString: testTokenString)
    self.refreshTokenRepository.issuedFirstRefreshTokenResult = Just(testRefreshToken)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // refresh token 저장 성공 설정
    self.refreshTokenRepository.saveRefreshTokenResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // When
    let testAuthCode = "test_authorization_code".data(using: .utf8)!
    let authProvider = createAppleAuthProvider(authorizationCode: testAuthCode)
    sut.signIn(authProvider: authProvider)
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
    XCTAssertEqual(firebaseAuthRepository.signInCallCount, 1)
    XCTAssertEqual(refreshTokenRepository.isSavedRefreshTokenCallCount, 1)
    XCTAssertEqual(pushNotiRestorationStateRepository.saveRestoreStateCallCount, 1)
    XCTAssertEqual(refreshTokenRepository.issuedFirstRefreshTokenCallCount, 1)
    XCTAssertEqual(refreshTokenRepository.saveRefreshTokenCallCount, 1)
    
    // 푸시 알림 복원 상태가 false로 설정되었는지 확인
    XCTAssertNotNil(pushNotiRestorationStateRepository.lastSavedRestorationState)
    XCTAssertFalse(pushNotiRestorationStateRepository.lastSavedRestorationState?.shouldRestore ?? true)
    
    // 올바른 authorizationCode로 refresh token을 발급받았는지 확인
    XCTAssertEqual(refreshTokenRepository.lastAuthorizationCode, testAuthCode)
    
    // 발급받은 refresh token이 제대로 저장되었는지 확인
    XCTAssertNotNil(refreshTokenRepository.lastSavedRefreshToken)
    XCTAssertEqual(refreshTokenRepository.lastSavedRefreshToken?.tokenString, testTokenString)
  }
  
  func test_재로그인_성공() {
    // Given
    let expectation = XCTestExpectation(description: "재로그인 성공")
    
    // 인증 성공 설정
    self.firebaseAuthRepository.signInResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // refresh token이 이미 존재함 설정
    self.refreshTokenRepository.isSavedRefreshTokenResult = Just(true)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // pushNoti 알림 복원 상태 저장 성공 설정
    self.pushNotiRestorationStateRepository.saveRestoreStateResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // When
    let authProvider = createAppleAuthProvider()
    sut.signIn(authProvider: authProvider)
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
    XCTAssertEqual(firebaseAuthRepository.signInCallCount, 1)
    XCTAssertEqual(refreshTokenRepository.isSavedRefreshTokenCallCount, 1)
    XCTAssertEqual(pushNotiRestorationStateRepository.saveRestoreStateCallCount, 1)
    XCTAssertEqual(refreshTokenRepository.issuedFirstRefreshTokenCallCount, 0)
    XCTAssertEqual(refreshTokenRepository.saveRefreshTokenCallCount, 0)
    
    // 푸시 알림 복원 상태가 true로 설정되었는지 확인
    XCTAssertNotNil(pushNotiRestorationStateRepository.lastSavedRestorationState)
    XCTAssertTrue(pushNotiRestorationStateRepository.lastSavedRestorationState?.shouldRestore ?? false)
  }
  
  func test_Firebase인증실패_에러발생() {
    // Given
    let expectation = XCTestExpectation(description: "Firebase 인증 실패 시 에러 발생")
    
    // 인증 실패 설정
    let expectedError = NSError(domain: "test", code: 1, userInfo: nil)
    self.firebaseAuthRepository.signInResult = Fail(error: expectedError)
      .eraseToAnyPublisher()
    
    // When
    let authProvider = createAppleAuthProvider()
    sut.signIn(authProvider: authProvider)
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
    XCTAssertEqual(firebaseAuthRepository.signInCallCount, 1)
    XCTAssertEqual(refreshTokenRepository.isSavedRefreshTokenCallCount, 0)
    XCTAssertEqual(pushNotiRestorationStateRepository.saveRestoreStateCallCount, 0)
  }
  
  func test_RefreshToken발급실패_에러발생() {
    // Given
    let expectation = XCTestExpectation(description: "Refresh Token 발급 실패 시 에러 발생")
    
    // 인증 성공 설정
    self.firebaseAuthRepository.signInResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // refresh token이 존재하지 않음 설정
    self.refreshTokenRepository.isSavedRefreshTokenResult = Just(false)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // pushNoti 알림 복원 상태 저장 성공 설정
    self.pushNotiRestorationStateRepository.saveRestoreStateResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // refresh token 발급 실패 설정
    let expectedError = NSError(domain: "test", code: 2, userInfo: nil)
    self.refreshTokenRepository.issuedFirstRefreshTokenResult = Fail(error: expectedError)
      .eraseToAnyPublisher()
    
    // When
    let testAuthCode = "test_authorization_code".data(using: .utf8)!
    let authProvider = createAppleAuthProvider(authorizationCode: testAuthCode)
    sut.signIn(authProvider: authProvider)
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
    XCTAssertEqual(firebaseAuthRepository.signInCallCount, 1)
    XCTAssertEqual(refreshTokenRepository.isSavedRefreshTokenCallCount, 1)
    XCTAssertEqual(pushNotiRestorationStateRepository.saveRestoreStateCallCount, 1)
    XCTAssertEqual(refreshTokenRepository.issuedFirstRefreshTokenCallCount, 1)
    XCTAssertEqual(refreshTokenRepository.saveRefreshTokenCallCount, 0)
  }
  
  func test_RefreshToken저장실패_에러발생() {
    // Given
    let expectation = XCTestExpectation(description: "Refresh Token 저장 실패 시 에러 발생")
    
    // 인증 성공 설정
    self.firebaseAuthRepository.signInResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // refresh token이 존재하지 않음 설정
    self.refreshTokenRepository.isSavedRefreshTokenResult = Just(false)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // pushNoti 알림 복원 상태 저장 성공 설정
    self.pushNotiRestorationStateRepository.saveRestoreStateResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // refresh token 발급 성공 설정
    let testTokenString = "test_refresh_token"
    let testRefreshToken = RefreshToken(tokenString: testTokenString)
    self.refreshTokenRepository.issuedFirstRefreshTokenResult = Just(testRefreshToken)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // refresh token 저장 실패 설정
    let expectedError = NSError(domain: "test", code: 3, userInfo: nil)
    self.refreshTokenRepository.saveRefreshTokenResult = Fail(error: expectedError)
      .eraseToAnyPublisher()
    
    // When
    let testAuthCode = "test_authorization_code".data(using: .utf8)!
    let authProvider = createAppleAuthProvider(authorizationCode: testAuthCode)
    sut.signIn(authProvider: authProvider)
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
    XCTAssertEqual(firebaseAuthRepository.signInCallCount, 1)
    XCTAssertEqual(refreshTokenRepository.isSavedRefreshTokenCallCount, 1)
    XCTAssertEqual(pushNotiRestorationStateRepository.saveRestoreStateCallCount, 1)
    XCTAssertEqual(refreshTokenRepository.issuedFirstRefreshTokenCallCount, 1)
    XCTAssertEqual(refreshTokenRepository.saveRefreshTokenCallCount, 1)
  }
  
  func test_재인증_성공() {
    // Given
    let expectation = XCTestExpectation(description: "재인증 성공")
    
    // 재인증 성공 설정
    self.firebaseAuthRepository.reauthenticateResult = Just(())
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // When
    let testFullName = PersonNameComponents(givenName: "Test", familyName: "User")
    let authProvider = createAppleAuthProvider(fullName: testFullName)
    sut.reauthenticate(authProvider: authProvider)
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
    XCTAssertEqual(firebaseAuthRepository.reauthenticateCallCount, 1)
    
    // 올바른 매개변수로 호출되었는지 확인
    XCTAssertEqual(firebaseAuthRepository.lastIdToken, "test_id_token")
    XCTAssertEqual(firebaseAuthRepository.lastNonce, "test_nonce")
    XCTAssertEqual(firebaseAuthRepository.lastFullName?.givenName, "Test")
    XCTAssertEqual(firebaseAuthRepository.lastFullName?.familyName, "User")
  }
  
  func test_재인증_실패() {
    // Given
    let expectation = XCTestExpectation(description: "재인증 실패 시 에러 발생")
    
    // 재인증 실패 설정
    let expectedError = NSError(domain: "test", code: 4, userInfo: nil)
    self.firebaseAuthRepository.reauthenticateResult = Fail(error: expectedError)
      .eraseToAnyPublisher()
    
    // When
    let authProvider = createAppleAuthProvider()
    sut.reauthenticate(authProvider: authProvider)
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
    XCTAssertEqual(firebaseAuthRepository.reauthenticateCallCount, 1)
  }
} 