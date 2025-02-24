//
//  UserDefaultsFake.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 12/15/24.
//

import Foundation

final class UserDefaultsFake: UserDefaults {
  private var storage: [String: Any] = [:]
  
  override func set(_ value: Any?, forKey defaultName: String) {
    self.storage[defaultName] = value
  }
  
  override func object(forKey defaultName: String) -> Any? {
    return self.storage[defaultName]
  }
  
  override func removeObject(forKey defaultName: String) {
    self.storage.removeValue(forKey: defaultName)
  }
}
