////
////  AuthNetworkService.swift
////  FreshNote
////
////  Created by SeokHyun on 1/21/25.
////
//
//import Combine
//import Foundation
//
//enum AuthNetworkServiceError: Error {
//  case urlError
//  case decodingError
//}
//
//protocol AuthNetworkService {
//  func requestRefreshToken(code: String) -> AnyPublisher<String, any Error>
//}
//
//final class DefaultAuthNetworkService: AuthNetworkService {
//  func requestRefreshToken(code: String) -> AnyPublisher<String, any Error> {
//    guard
//      let encodedString = "https://us-central1-freshnote-6bee5.cloudfunctions.net/getRefreshToken?code=\(code)"
//        .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
//      let url = URL(string: encodedString)
//    else { return Fail(error: AuthNetworkServiceError.urlError).eraseToAnyPublisher() }
//    
//    return URLSession.shared.dataTaskPublisher(for: url)
//      .map(\.data)
//      .tryMap { data -> String in
//        guard let token = String(data: data, encoding: .utf8) else {
//          throw AuthNetworkServiceError.decodingError
//        }
//        return token
//      }
//      .eraseToAnyPublisher()
//  }
//}
