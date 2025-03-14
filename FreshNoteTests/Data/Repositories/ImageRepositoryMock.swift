//
//  ImageRepositoryMock.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import Combine
import Foundation

final class ImageRepositoryMock: ImageRepository {
  private(set) var saveImageCallCount = 0
  private(set) var deleteImageCallCount = 0
  
  private(set) var lastDeletedImageURL: URL?
  private(set) var lastSavedImageData: Data?
  private(set) var lastSavedFileName: String?
  
  var saveImageResult: AnyPublisher<URL, any Error>!
  var deleteImageResult: AnyPublisher<Void, any Error>!
  
  func resetCallCounts() {
    self.saveImageCallCount = 0
    self.deleteImageCallCount = 0
    
    self.lastDeletedImageURL = nil
    self.lastSavedImageData = nil
    self.lastSavedFileName = nil
  }
  
  func saveImage(with data: Data, fileName: String) -> AnyPublisher<URL, any Error> {
    self.saveImageCallCount += 1
    self.lastSavedImageData = data
    self.lastSavedFileName = fileName
    return self.saveImageResult
  }
  
  func deleteImage(with url: URL) -> AnyPublisher<Void, any Error> {
    self.deleteImageCallCount += 1
    self.lastDeletedImageURL = url
    return self.deleteImageResult
  }
} 