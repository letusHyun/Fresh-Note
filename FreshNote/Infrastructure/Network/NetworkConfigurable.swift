//
//  NetworkConfigurable.swift
//  FreshNote
//
//  Created by SeokHyun on 1/21/25.
//

import Foundation

protocol NetworkConfigurable {
  var baseURL: URL { get }
  var headers: [String: String] { get }
  /// 공통으로 사용되는 쿼리
  var queryParameters: [String: String] { get }
}

struct APIDataNetworkConfig: NetworkConfigurable {
  let baseURL: URL
  let headers: [String : String]
  let queryParameters: [String : String]
  
  init(
    baseURL: URL,
    headers: [String : String] = [:],
    queryParameters: [String : String] = [:]
  ) {
    self.baseURL = baseURL
    self.headers = headers
    self.queryParameters = queryParameters
  }
}
