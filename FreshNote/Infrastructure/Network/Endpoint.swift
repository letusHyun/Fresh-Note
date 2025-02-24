//
//  Endpoint.swift
//  FreshNote
//
//  Created by SeokHyun on 1/21/25.
//

import Foundation

class Endpoint<R>: ResponseRequestable {
  typealias Response = R
  
  let path: String
  let queryParameters: [String: Any]
  let responseDecoder: ResponseDecoder
  let queryParametersEncodable: Encodable?
  
  init(
    path: String,
    queryParameters: [String: Any] = [:],
    responseDecoder: ResponseDecoder = JSONResponseDecoder(),
    queryParametersEncodable: Encodable? = nil
  ) {
    self.path = path
    self.queryParameters = queryParameters
    self.responseDecoder = responseDecoder
    self.queryParametersEncodable = queryParametersEncodable
  }
}

enum RequestGenerationError: Error {
  case components
  case makingURLError
}

protocol Requestable {
  var path: String { get }
  var queryParameters: [String: Any] { get }
  var queryParametersEncodable: Encodable? { get }
}

extension Requestable {
  func url(with config: NetworkConfigurable) throws -> URL {
    let baseURL = config.baseURL.absoluteString.last != "/"
    ? config.baseURL.absoluteString + "/"
    : config.baseURL.absoluteString
    
    let endpoint = baseURL.appending(self.path)
    
    guard var urlComponents = URLComponents(string: endpoint) else {
      throw RequestGenerationError.components
    }
    
    var urlQueryItems = [URLQueryItem]()
    
    let queryParameters = try self.queryParametersEncodable?.toDictionary() ?? self.queryParameters
    queryParameters.forEach { urlQueryItems.append(URLQueryItem(name: $0.key, value: "\($0.value)")) }
    config.queryParameters.forEach { urlQueryItems.append(URLQueryItem(name: $0.key, value: $0.value)) }
    urlComponents.queryItems = !urlQueryItems.isEmpty ? urlQueryItems : nil

    guard let url = urlComponents.url else {
      throw RequestGenerationError.components
    }
    
    guard let urlString = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
          let url = URL(string: urlString) else {
      throw RequestGenerationError.makingURLError
    }
    
    return url
  }
}


protocol ResponseRequestable: Requestable {
  associatedtype Response
  var responseDecoder: ResponseDecoder { get }
}
