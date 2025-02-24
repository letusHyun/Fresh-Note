//
//  NetworkService.swift
//  FreshNote
//
//  Created by SeokHyun on 1/21/25.
//

import Combine
import Foundation

enum NetworkError: Error {
  case error
  case urlGeneration
  case noData
  case serverError
  case notConnected
  case cancelled
  case generic(Error)
}

protocol NetworkSessionManager {
  func request(_ url: URL) -> AnyPublisher<(data: Data, response: URLResponse), URLError>
}

protocol NetworkService {
  func request(endpoint: Requestable) -> AnyPublisher<Data, NetworkError>
}

/// 네트워크 에러 발생 log를 추적하는 객체입니다.
protocol NetworkErrorLogger {
  func log(error: Error)
  func log(statusCode: Int?)
}

final class DefaultNetworkErrorLogger: NetworkErrorLogger {
  func log(error: Error) {
    printIfDebug("\(error)")
  }
  
  func log(statusCode: Int?) {
    guard let statusCode else { return }
    printIfDebug("statusCode: \(statusCode)")
  }
}

final class DefaultNetworkService {
  private let config: any NetworkConfigurable
  private let sessionManager: any NetworkSessionManager
  private let logger: any NetworkErrorLogger
  
  init(
    config: any NetworkConfigurable,
    sessionManager: any NetworkSessionManager = DefaultNetworkSessionManager(),
    logger: any NetworkErrorLogger = DefaultNetworkErrorLogger()
  ) {
    self.config = config
    self.sessionManager = sessionManager
    self.logger = logger
  }
}

// MARK: - NetworkService
extension DefaultNetworkService: NetworkService {
  func request(endpoint: any Requestable) -> AnyPublisher<Data, NetworkError> {
    guard let url = try? endpoint.url(with: self.config) else {
      return Fail(error: NetworkError.urlGeneration).eraseToAnyPublisher()
    }
     return self.sessionManager
      .request(url)
      .mapError { [weak self] error -> NetworkError in // URLError 발생시, NetworkError로 변환
        self?.logger.log(error: error)
        
        switch error.code {
        case .notConnectedToInternet: return .notConnected
        case .cancelled: return .cancelled
        default: return .generic(error)
        }
      }
      .tryMap { [weak self] result in
        guard let httpResponse = result.response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
          let httpResponse = result.response as? HTTPURLResponse
          self?.logger.log(statusCode: httpResponse?.statusCode)
          
          throw NetworkError.serverError
        }
        return result.data
      }
      .mapError { error -> NetworkError in
        if let networkError = error as? NetworkError {
          return networkError
        }
        return NetworkError.generic(error)
      }
      .eraseToAnyPublisher()
  }
}

// MARK: - NetworkSessionManager
final class DefaultNetworkSessionManager: NetworkSessionManager {
  func request(_ url: URL) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
    return URLSession.shared
      .dataTaskPublisher(for: url)
      .eraseToAnyPublisher()
  }
}

// MARK: - fileprivate
fileprivate func printIfDebug(_ string: String) {
#if DEBUG
  print(string)
#endif
}
