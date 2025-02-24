//
//  CommonResponseDTO.swift
//  FreshNote
//
//  Created by SeokHyun on 1/22/25.
//

import Foundation

struct CommonResponseDTO<T: Decodable>: Decodable {
  let status: Bool
  let message: String
  let responseDTO: T?
  
  enum CodingKeys: String, CodingKey {
    case status
    case message
    case responseDTO = "data"
  }
}
