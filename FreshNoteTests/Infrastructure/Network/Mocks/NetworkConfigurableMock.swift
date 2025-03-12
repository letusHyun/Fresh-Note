//
//  NetworkConfigurableMock.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/12/25.
//

@testable import Fresh_Note_Dev
import Foundation

final class NetworkConfigurableMock: NetworkConfigurable {
  var baseURL: URL = URL(string: "https://mock.test.com")!
  
  var headers: [String : String] = [:]
  
  var queryParameters: [String : String] = [:]
}
