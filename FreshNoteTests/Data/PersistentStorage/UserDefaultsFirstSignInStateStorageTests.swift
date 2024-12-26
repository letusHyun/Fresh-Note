////
////  UserDefaultsFirstSignInStateStorageTests.swift
////  FreshNoteTests
////
////  Created by SeokHyun on 12/15/24.
////
//
//import Combine
//import XCTest
//
//final class UserDefaultsFirstSignInStateStorageTests: XCTestCase {
//  private var sut: FirstSignInStateStorage!
//  private var subscriptions: Set<AnyCancellable>!
//  private var expectation: XCTestExpectation!
//  
//  override func setUp() {
//    super.setUp()
//    self.sut = UserDefaultsFirstSignInStateStorage(userDefaults: UserDefaultsFake())
//    self.subscriptions = Set<AnyCancellable>()
//    self.expectation = XCTestExpectation(description: "async operation")
//  }
//  
//  override func tearDown() {
//    super.tearDown()
//    self.sut = nil
//    self.subscriptions = nil
//    self.expectation = nil
//  }
//  
//  func test_save시_데이터가_잘_저장되는지() {
//    // Arrange
//    var isReceivedValue = false
//    
//    // Act
//    self.sut
//      .saveFirstSignInState()
//      .sink { [weak self] completion in
//        if case let .failure(error) = completion {
//          XCTFail("saveSignInState error: \(error)")
//        }
//        self?.expectation.fulfill()
//      } receiveValue: { _ in
//        isReceivedValue = true
//      }.store(in: &self.subscriptions)
//
//    self.wait(for: [self.expectation], timeout: 2.0)
//    
//    // Assert
//    XCTAssert(isReceivedValue, "value를 받아야하는데, 받지 못함")
//  }
//  
//  func test_fetch시_데이터가_잘_fetch되는지() {
//    // Arrange
//    let savePublisher = self.sut
//      .saveFirstSignInState()
//    
//    // Act
//    savePublisher
//      .flatMap { [weak self] _ in
//        guard let self else { return Empty<Bool, any Error>().eraseToAnyPublisher() }
//        
//        return self.sut.fetchFirstSignInState()
//      }
//      .sink { [weak self] completion in
//        if case let .failure(error) = completion {
//          XCTFail("fetchFirstSignInState error: \(error)")
//        }
//        self?.expectation.fulfill()
//      } receiveValue: { isFirstSignIn in
//        // Assert
//        XCTAssertEqual(isFirstSignIn, "fetch value와 결과값이 같아야하는데 다름")
//      }
//      .store(in: &self.subscriptions)
//    
//    self.wait(for: [self.expectation], timeout: 2.0)
//  }
//}
