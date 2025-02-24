//
//  DefaultDataTransferService.swift
//  FreshNote
//
//  Created by SeokHyun on 1/21/25.
//

import Combine
import Foundation

enum DataTransferError: Error {
  case noResponse
  case parsing(Error)
  case referenceError
  case networkFailure(NetworkError)
  case statusError
}

protocol DataTransferErrorLogger {
  func log(error: any Error)
}

protocol DataTransferService {
  func request<T: Decodable, E: ResponseRequestable>(
    with endpoint: E,
    on queue: DispatchQueue
  ) -> AnyPublisher<T?, DataTransferError> where E.Response == T
}

protocol ResponseDecoder {
  func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable
}

final class DefaultDataTransferService {
  private let networkService: any NetworkService
  private let errorLogger: any DataTransferErrorLogger
  
  init(
    networkService: any NetworkService,
    errorLogger: any DataTransferErrorLogger = DefaultDataTransferErrorLogger()
  ) {
    self.networkService = networkService
    self.errorLogger = errorLogger
  }
}

// MARK: - DataTransferService
extension DefaultDataTransferService: DataTransferService {
  func request<T: Decodable, E: ResponseRequestable>(
    with endpoint: E,
    on queue: DispatchQueue
  ) -> AnyPublisher<T?, DataTransferError> where E.Response == T {
    return self.networkService
      .request(endpoint: endpoint)
      .receive(on: queue)
      .mapError { [weak self] error in
        self?.errorLogger.log(error: error)
        return DataTransferError.networkFailure(error)
      }
      .flatMap { [weak self] data in
        guard let self else {
          return Fail<T?, DataTransferError>(error: .referenceError).eraseToAnyPublisher()
        }
        
        return self.decode(data: data, decoder: endpoint.responseDecoder)
      }
      .eraseToAnyPublisher()
  }
  
  // MARK: - Private
  private func decode<T: Decodable>(data: Data, decoder: ResponseDecoder) -> AnyPublisher<T?, DataTransferError> {
    return Result {
      let commonResponseDTO = try decoder.decode(CommonResponseDTO<T>.self, from: data)
      guard commonResponseDTO.status else {
        throw DataTransferError.statusError
      }
      return commonResponseDTO.responseDTO
    }
    .mapError { error in
      self.errorLogger.log(error: error)
      return DataTransferError.parsing(error)
    }
    .publisher
    .eraseToAnyPublisher()
  }
}

// MARK: - Response Decoders
/// 외부 api가 json으로 응답을 주는경우, 사용하는 객체입니다.
final class JSONResponseDecoder: ResponseDecoder {
  init() { }
  
  private let jsonDecoder = JSONDecoder()
  
  func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
    return try self.jsonDecoder.decode(type, from: data)
  }
}

// MARK: - DataTransferErrorLogger
final class DefaultDataTransferErrorLogger: DataTransferErrorLogger {
  func log(error: any Error) {
    printIfDebug("--------------")
    printIfDebug("\(error)")
  }
}

fileprivate func printIfDebug(_ string: String) {
#if DEBUG
  print(string)
#endif
}
