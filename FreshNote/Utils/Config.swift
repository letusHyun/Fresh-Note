//
//  Config.swift
//  FreshNote
//
//  Created by SeokHyun on 2/25/25.
//

import Foundation

enum Config {
  static let baseURL = Bundle.main.infoDictionary?["BASE_URL"] as! String
}
