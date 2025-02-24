//
//  ImageRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 11/29/24.
//

import Combine
import Foundation

protocol ImageRepository {
  func saveImage(with data: Data, fileName: String) -> AnyPublisher<URL, any Error>
  func deleteImage(with url: URL) -> AnyPublisher<Void, any Error>
}
