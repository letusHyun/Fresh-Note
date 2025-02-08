//
//  FirstLaunchStorage.swift
//  FreshNote
//
//  Created by SeokHyun on 1/20/25.
//

import Combine
import Foundation

protocol FirstLaunchStorage {
  func saveFirstLaunchState() -> AnyPublisher<Void, any Error>
  func fetchFirstLaunchState() -> AnyPublisher<Bool, any Error>
}
