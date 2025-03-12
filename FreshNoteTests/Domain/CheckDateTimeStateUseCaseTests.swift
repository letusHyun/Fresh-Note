//
//  CheckDateTimeStateUseCaseTests.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/12/25.
//
@testable import Fresh_Note_Dev
import Combine
import XCTest

final class CheckDateTimeStateUseCaseTests: XCTestCase {
  final class DateTimeRepositoryStub: DateTimeRepository {
    let isSaved: Bool
    init(isSaved: Bool) {
      self.isSaved = isSaved
    }
    
    func fetchDateTime() -> AnyPublisher<DateTime, any Error> {
      Just(DateTime(date: 1, hour: 2, minute: 3))
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }
    
    func saveDateTime(dateTime: DateTime) -> AnyPublisher<Void, any Error> {
      Just(())
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }
    
    func isSavedDateTime() -> AnyPublisher<Bool, any Error> {
      Just(self.isSaved)
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }
    
    func updateDateTime(dateTime: DateTime) -> AnyPublisher<Void, any Error> {
      Just(())
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }
    
    func deleteCachedDateTime() -> AnyPublisher<Void, any Error> {
      Just(())
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }
  }
  
  private var subscriptions: Set<AnyCancellable>!
  private var expectation: XCTestExpectation!
  
  override func setUp() {
    super.setUp()
    self.subscriptions = .init()
    self.expectation = XCTestExpectation(description: "비동기 처리 담당")
  }
  
  override func tearDown() {
    super.tearDown()
    self.subscriptions = nil
    self.expectation = nil
  }
  
  func test_execute를_호출하면dateTime의_저장여부를_반환한다() {
    // given
    let expectedValue: Bool = true
    let sut = DefaultCheckDateTimeStateUseCase(dateTimeRepository: DateTimeRepositoryStub(isSaved: expectedValue))
    var isCalled: Bool = false
    
    // when
    sut.execute()
      .sink { completion in
        if case .failure = completion {
          XCTFail("error가 발생하면 안됩니다.")
        }
      } receiveValue: { [weak self] isSavedDateTime in
        XCTAssertEqual(expectedValue, isSavedDateTime)
        isCalled = true
        self?.expectation.fulfill()
      }
      .store(in: &self.subscriptions)
    
    self.wait(for: [self.expectation])
    
    // then
    XCTAssertTrue(isCalled)
  }
}
