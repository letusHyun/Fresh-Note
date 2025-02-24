//
//  DocumentID.swift
//  FreshNote
//
//  Created by SeokHyun on 11/28/24.
//

import Foundation

enum DocumentIDError: Error {
  case invalidID
}

struct DocumentID {
  let didString: String
  
  ///  requestDTO를 정의하기 위해서 Entity를 생성할 때 사용합니다.
  init() {
    self.didString = UUID().uuidString
  }
  
  /// responseDTO를 사용해서 Entity를 생성할 때 사용합니다.
  init?(from string: String) {
      if Self.isValid(didString: string) {
          self.didString = string
      } else {
          return nil
      }
  }
  
  static func isValid(didString: String) -> Bool {
      return didString.range(of: "\\w{8}-\\w{4}-\\w{4}-\\w{4}-\\w{12}", options: .regularExpression) != nil
  }
}
