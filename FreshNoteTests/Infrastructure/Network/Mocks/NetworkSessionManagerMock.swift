//
//  NetworkSessionManagerMock.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/12/25.
//

@testable import Fresh_Note_Dev
import Combine
import Foundation

final class NetworkSessionManagerMock: NetworkSessionManager {
  private var result: (data: Data, response: URLResponse)?
  private var urlError: URLError?
  
  init(result: (data: Data, response: URLResponse)?, urlError: URLError?) {
    self.result = result
    self.urlError = urlError
  }
  
  func request(_ url: URL) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
    guard let result = self.result else {
      return Fail(error: self.urlError ?? URLError(_nsError: NSError()))
        .eraseToAnyPublisher()
    }
    
    return Just((result.data, result.response))
      .setFailureType(to: URLError.self)
      .eraseToAnyPublisher()
  }
}
