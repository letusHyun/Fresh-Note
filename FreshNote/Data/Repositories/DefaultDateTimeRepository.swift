//
//  DefaultDateTimeRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 10/26/24.
//

import Foundation
import Combine
import FirebaseFirestore

final class DefaultDateTimeRepository: DateTimeRepository {
  private let firebaseNetworkService: any FirebaseNetworkService
  private let backgroundQueue: DispatchQueue
  
  init(
    firebaseNetworkService: any FirebaseNetworkService,
    backgroundQueue: DispatchQueue = DispatchQueue.global(qos: .userInitiated)
  ) {
    self.firebaseNetworkService = firebaseNetworkService
    self.backgroundQueue = backgroundQueue
  }
  
  func fetchDateTime() -> AnyPublisher<Alarm, any Error> {
    guard let userID = FirebaseUserManager.shared.userID else {
      return Fail(error: FirebaseUserError.invalidUid).eraseToAnyPublisher()
    }
    
    let publisher: AnyPublisher<AlarmResponseDTO, any Error> = self.firebaseNetworkService.getDocument(
      documentPath: FirestorePath.userID(userID: userID)
    )
      .receive(on: self.backgroundQueue)
      .eraseToAnyPublisher()
    
    return publisher.tryMap { $0.toDomain() }
      .eraseToAnyPublisher()
  }
  
  func isSavedDateTime() -> AnyPublisher<Bool, any Error> {
    return self.fetchDateTime()
      .map { _ in return true }
      .catch { error -> AnyPublisher<Bool, any Error> in
        if case FirebaseNetworkServiceError.invalidData = error {
          return Just(false)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        }
        return Fail(error: error)
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
  
  func saveDateTime(date: Int, hour: Int, minute: Int) -> AnyPublisher<Void, any Error> {
    guard let userID = FirebaseUserManager.shared.userID
    else { return Fail(error: FirebaseUserError.invalidUid).eraseToAnyPublisher() }
    
    let requestDTO = AlarmRequestDTO(date: date, hour: hour, minute: minute)
    return self.firebaseNetworkService.setDocument(
      documentPath: FirestorePath.userID(userID: userID),
      requestDTO: requestDTO,
      merge: true
    )
    .receive(on: self.backgroundQueue)
    .eraseToAnyPublisher()
  }
}
