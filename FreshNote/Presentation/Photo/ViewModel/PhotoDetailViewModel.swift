//
//  PhotoDetailViewModel.swift
//  FreshNote
//
//  Created by SeokHyun on 2/13/25.
//

import Combine
import Foundation

struct PhotoDetailViewModelActions {
  
}

protocol PhotoDetailViewModel: PhotoDetailViewModelInput & PhotoDetailViewModelOutput { }

protocol PhotoDetailViewModelInput {
  func viewDidLoad()
}

protocol PhotoDetailViewModelOutput {
  var imageDataPublisher: AnyPublisher<Data, Never> { get }
  var errorPublisher: AnyPublisher<(any Error)?, Never> { get }
}

final class DefaultPhotoDetailViewModel: PhotoDetailViewModel {
  // MARK: - Properties
  private var subscriptions: Set<AnyCancellable> = []
  private let imageData: Data
  
  // MARK: - Output
  var imageDataPublisher: AnyPublisher<Data, Never> { self.imageDataSubject.eraseToAnyPublisher() }
  var errorPublisher: AnyPublisher<(any Error)?, Never> { self.$error.eraseToAnyPublisher() }
  
  private let imageDataSubject: PassthroughSubject<Data, Never> = .init()
  @Published private var error: (any Error)?
  
  // MARK: - LifeCycle
  init(imageData: Data) {
    self.imageData = imageData
  }
  
  // MARK: - Input
  func viewDidLoad() {
    self.imageDataSubject.send(self.imageData)
  }
}
