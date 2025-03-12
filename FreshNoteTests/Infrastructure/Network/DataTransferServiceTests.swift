//
//  DataTransferServiceTests.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/12/25.
//

@testable import Fresh_Note_Dev
import Combine
import XCTest

private struct MockModel: Decodable {
  let name: String
}

final class DataTransferServiceTests: XCTestCase {
  private var subscriptions: Set<AnyCancellable>!
  private var expectation: XCTestExpectation!
  
  override func setUp() {
    super.setUp()
    self.subscriptions = .init()
    self.expectation = XCTestExpectation(description: "비동기 처리를 담당합니다.")
  }
  
  override func tearDown() {
    super.tearDown()
    self.subscriptions = nil
    self.expectation = nil
  }
  
  func tests_receiveValued가_호출되면_Decodable을_준수하는_객체를_받아야한다() {
    // given
    let expectedValue = "Hello"
    
    let responseData = """
        {
          "status": true,
          "message": "Success",
          "data": { 
            "name": "\(expectedValue)"
          }
        }
    """
      .data(using: .utf8)!
    
    let response = HTTPURLResponse(
      url: URL(string: "https://mock.test.com")!,
      statusCode: 200,
      httpVersion: nil,
      headerFields: nil
    )! as URLResponse
    
    let networkService = DefaultNetworkService(
      config: NetworkConfigurableMock(),
      sessionManager: NetworkSessionManagerMock(
        result: (data: responseData, response: response),
        urlError: nil
      )
    )
    let sut = DefaultDataTransferService(networkService: networkService)
    var isCalled: Bool = false
    
    // when
    sut.request(
      with: Endpoint<MockModel>(path: "https://mock.endpoint.com"),
      on: DispatchQueue.main
    )
    .sink { completion in
      
    } receiveValue: { [weak self] result in
      guard let name = result?.name else {
        XCTFail("response가 옵셔널이 아니어야 합니다.")
        return
      }
      
      XCTAssertEqual(expectedValue, name)
      isCalled = true
      self?.expectation.fulfill()
    }
    .store(in: &self.subscriptions)

    wait(for: [self.expectation], timeout: 1.0)
    
    // then
    XCTAssertTrue(isCalled)
  }
  
  func tests_invalidResponse를_받으면_decode되지_않아야한다() {
    // given
    let responseData = """
        {
          "status": true,
          "message": "Success",
          "data": { 
            "age": 12
          }
        }
    """
      .data(using: .utf8)!
    
    let response = HTTPURLResponse(
      url: URL(string: "https://mock.test.com")!,
      statusCode: 200,
      httpVersion: nil,
      headerFields: nil
    )! as URLResponse
    
    let sut = DefaultDataTransferService(networkService: DefaultNetworkService(
      config: NetworkConfigurableMock(),
      sessionManager: NetworkSessionManagerMock(
        result: (data: responseData, response: response),
        urlError: nil
      )
    ))
    
    var isCalled: Bool = false
    
    // when
    sut
      .request(with: Endpoint<MockModel>(path: "https://mock.endpoint.com"), on: .main)
      .sink { [weak self] completion in
        if case .failure(let error) = completion, case .parsing = error {
          isCalled = true
          self?.expectation.fulfill()
        }
      } receiveValue: { _ in
        XCTFail("receiveValue가 호출되지 말아야 합니다.")
      }
      .store(in: &self.subscriptions)
    wait(for: [self.expectation], timeout: 1.0)
    
    // then
    XCTAssertTrue(isCalled)
  }
  
  func test_whenBadRequestReceived_shouldRethrowNetworkError() {
    // given
    let responseData = """
    {
      "invalidStructure": "nothing"
    }
    """
      .data(using: .utf8)!
    let response = HTTPURLResponse(
      url: URL(string: "test_url")!,
      statusCode: 500,
      httpVersion: nil,
      headerFields: nil
    )! as URLResponse
    
    let sut = DefaultDataTransferService(networkService: DefaultNetworkService(
      config: NetworkConfigurableMock(),
      sessionManager: NetworkSessionManagerMock(
        result: (data: responseData, response: response),
        urlError: nil
      )
    ))
    
    var isCalled: Bool = false
    
    // when
    sut
      .request(with: Endpoint<MockModel>(path: "https://mock.endpoint.com"), on: .main)
      .sink { [weak self] completion in
        if case .failure(let error) = completion,
           case .networkFailure(let error) = error,
           case .serverError = error {
          isCalled = true
          self?.expectation.fulfill()
        }
      } receiveValue: { result in
        XCTFail("receiveValue가 호출되지 않아야 합니다.")
      }
      .store(in: &self.subscriptions)
    
    wait(for: [self.expectation], timeout: 1.0)
    
    // then
    XCTAssertTrue(isCalled)
  }
}
