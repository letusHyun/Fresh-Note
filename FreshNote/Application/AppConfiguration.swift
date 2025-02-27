//
//  AppConfiguration.swift
//  FreshNote
//
//  Created by SeokHyun on 2/26/25.
//

import Foundation

final class AppConfiguration {
  // MARK: - Plist
  private static let infoDictionary: [String: Any] = {
    guard let dict = Bundle.main.infoDictionary else {
      fatalError("Plist file not found")
    }
    return dict
  }()
  
  // MARK: - Plist Values
  lazy var baseURL: URL = {
    guard let baseURLString = AppConfiguration.infoDictionary[Environment.Keys.Plist.baseURL.rawValue] as? String else {
      fatalError("Base URL not set in plist for this envirionment")
    }
    guard let url = URL(string: baseURLString) else {
      print("baseURLString: \(baseURLString)")
      fatalError("Base URL is invalid")
    }
    return url
  }()
}
