//
//  Encodable+.swift
//  FreshNote
//
//  Created by SeokHyun on 11/28/24.
//

import Foundation

extension Encodable {
  /// RequestDTO를 encoding하기 위해 딕셔너리로 변환합니다.
  func toDictionary() throws -> [String: Any]? {
    let data = try JSONEncoder().encode(self)
    let jsonData = try JSONSerialization.jsonObject(with: data)
    return jsonData as? [String : Any]
  }
}
