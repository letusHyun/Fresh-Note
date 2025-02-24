//
//  DefaultImageRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 11/29/24.
//

import Combine
import Foundation

final class DefaultImageRepository: ImageRepository {
  private let firebaseNetworkService: any FirebaseNetworkService
  private let backgroundQueue: DispatchQueue
  
  init(
    firebaseNetworkService: any FirebaseNetworkService,
    backgroundQueue: DispatchQueue = DispatchQueue.global(qos: .userInitiated)
  ) {
    self.firebaseNetworkService = firebaseNetworkService
    self.backgroundQueue = backgroundQueue
  }
  
  deinit {
    print("DEBUG: \(Self.self) deinit")
  }
  
  func saveImage(with data: Data, fileName: String) -> AnyPublisher<URL, any Error> {
    guard let userID = FirebaseUserManager.shared.userID else {
      return Fail(error: FirebaseUserError.invalidUid).eraseToAnyPublisher()
    }
    
    return self.firebaseNetworkService
      .uploadData(path: userID, fileName: fileName, data: data)
      .receive(on: self.backgroundQueue)
      .eraseToAnyPublisher()
  }
  
  func deleteImage(with url: URL) -> AnyPublisher<Void, any Error> {
    return self.firebaseNetworkService
      .deleteData(urlString: url.absoluteString)
      .receive(on: self.backgroundQueue)
      .eraseToAnyPublisher()
  }
}
