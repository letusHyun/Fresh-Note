@testable import Fresh_Note_Dev
import Combine
import XCTest

final class NetworkServiceTests: XCTestCase {
  private struct EndpointMock: Requestable {
    var path: String
    var queryParameters: [String : Any] = [:]
    var queryParametersEncodable: (any Encodable)?
    
    init(path: String) {
      self.path = path
    }
  }
    
  private var subscriptions: Set<AnyCancellable>!
  private var expectation: XCTestExpectation!
  
  override func setUp() {
    super.setUp()
    self.subscriptions = .init()
    self.expectation = XCTestExpectation(description: "비동기 호출을 담당합니다.")
  }
  
  override func tearDown() {
    super.tearDown()
    self.subscriptions = nil
    self.expectation = nil
  }
  
  func test_data를_전달하면_올바른response을_return받아야한다() {
    // given
    let config = NetworkConfigurableMock()
    let expectedData = "Response Data".data(using: .utf8)!
    let response = HTTPURLResponse(
      url: URL(string: "https://mock.test.com")!,
      statusCode: 200,
      httpVersion: nil,
      headerFields: nil
    )! as URLResponse
    
    var isSuccessed: Bool = false
    
    let sut = DefaultNetworkService(
      config: config,
      sessionManager: NetworkSessionManagerMock(
        result: (data: expectedData, response: response),
        urlError: nil
      )
    )
    
    // when
    sut.request(endpoint: EndpointMock(path: "https://mock.test.com"))
      .receive(on: DispatchQueue.main)
      .sink { completion in
        if case .failure(let error) = completion {
          XCTFail("적절한 response을 return받아야 합니다. error: \(error)")
          return
        }
        self.expectation.fulfill()
      } receiveValue: { data in
        XCTAssertEqual(expectedData, data)
        isSuccessed = true
      }
      .store(in: &self.subscriptions)
    
    wait(for: [self.expectation], timeout: 2.0)
    
    // then
    XCTAssertTrue(isSuccessed)
  }
  
  func test_error가_방출되면_completion의_failure_연관값이_NetworkError타입이어야한다() {
    // given
    let config = NetworkConfigurableMock()
    var isSuccessed: Bool = false
    
    let sut = DefaultNetworkService(
      config: config,
      sessionManager: NetworkSessionManagerMock(
        result: nil,
        urlError: URLError(URLError.Code(rawValue: 123))
      )
    )
    
    // when
    sut.request(endpoint: EndpointMock(path: "https://mock.test.com"))
      .receive(on: DispatchQueue.main)
      .sink { completion in
        if case .failure = completion {
          isSuccessed = true
          self.expectation.fulfill()
        }
      } receiveValue: { _ in
        XCTFail("value를 받으면 안됩니다.")
      }
      .store(in: &self.subscriptions)

    wait(for: [self.expectation], timeout: 2.0)
    
    // then
    XCTAssertTrue(isSuccessed)
  }
}
