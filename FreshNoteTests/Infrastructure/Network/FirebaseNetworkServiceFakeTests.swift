//
//  FirebaseNetworkServiceFakeTests.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 12/18/24.
//

import Combine
import XCTest

final class FirebaseNetworkServiceFakeTests: XCTestCase {
  struct RequestDTO: Encodable {
    let name: String
    let age: Int
  }
  
  struct ResponseDTO: Decodable {
    let name: String
    let age: Int
  }
  
  private var sut: (any FirebaseNetworkService)!
  private var subscriptions: Set<AnyCancellable>!
  private var expectation: XCTestExpectation!
  
  override func setUp() {
    super.setUp()
    self.sut = FirebaseNetworkServiceFake()
    self.subscriptions = Set<AnyCancellable>()
    self.expectation = XCTestExpectation(description: "비동기 호출")
  }
  
  override func tearDown() {
    super.tearDown()
    sut = nil
    subscriptions = nil
  }
  
  func test_setDocument호출시_데이터가_저장되는지() {
    // Arrange
    let dummyDocumentPath = "fake/documentPath"
    let dummyRequestDTO = RequestDTO(name: "user1", age: 21)
    var isReceivedValue = false
    
    // Act
    self.sut.setDocument(
      documentPath: dummyDocumentPath,
      requestDTO: dummyRequestDTO,
      merge: true
    )
    .sink { [weak self] completion in
      if case let .failure(error) = completion {
        XCTFail("error 발생: \(error)")
      }
      self?.expectation.fulfill()
    } receiveValue: { _ in
      isReceivedValue = true
    }
    .store(in: &subscriptions)
    
    self.wait(for: [self.expectation], timeout: 2.0)
    
    // Assert
    XCTAssertTrue(isReceivedValue)
  }
  
  func test_getDocument호출시_데이터를_가져오는지() {
    // Arrange
    let dummyDocumentPath = "fake/documentPath"
    let dummyRequestDTO = RequestDTO(name: "user1", age: 21)
    var result = false
    
    // Act
    self.sut.setDocument(
      documentPath: dummyDocumentPath,
      requestDTO: dummyRequestDTO,
      merge: true
    )
    .flatMap { [weak self] () -> AnyPublisher<ResponseDTO, any Error> in
      guard let self else { return Empty<ResponseDTO, any Error>().eraseToAnyPublisher() }
      
      return self.sut.getDocument(documentPath: dummyDocumentPath)
    }
    .sink { [weak self] completion in
      if case let .failure(error) = completion {
        XCTFail("error 발생: \(error)")
      }
      self?.expectation.fulfill()
    } receiveValue: { responseDTO in
      let ageMatches = dummyRequestDTO.age == responseDTO.age
      let nameMatches = dummyRequestDTO.name == responseDTO.name
      result = ageMatches && nameMatches
    }
    .store(in: &subscriptions)

    // Assert
    XCTAssertTrue(result)
  }
  
//  func test_getDocuments호출시_데이터를_가져오는지() {
//    
//  }
}
