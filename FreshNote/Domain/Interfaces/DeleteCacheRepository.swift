//
//  DeleteCacheRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 2/7/25.
//

import Combine
import Foundation

protocol DeleteCacheRepository {
  func deleteCaches() -> AnyPublisher<[DocumentID], any Error>
}
