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
  private let dateTimeStorage: any DateTimeStorage
  
  init(
    firebaseNetworkService: any FirebaseNetworkService,
    backgroundQueue: DispatchQueue = DispatchQueue.global(qos: .userInitiated),
    dateTimeStorage: any DateTimeStorage
  ) {
    self.firebaseNetworkService = firebaseNetworkService
    self.backgroundQueue = backgroundQueue
    self.dateTimeStorage = dateTimeStorage
  }
  
  func fetchDateTime() -> AnyPublisher<DateTime, any Error> {
    return self.dateTimeStorage
      .hasDateTime()
      .flatMap { [weak self] hasDateTime -> AnyPublisher<DateTime, any Error> in
        guard let self else { return Empty().eraseToAnyPublisher() }
        
        // storage에 dateTime이 존재한다면
        if hasDateTime {
          return self.dateTimeStorage.fetchDateTime()
        }
        
        // storage에 dateTime이 존재하지 않는다면
        guard let userID = FirebaseUserManager.shared.userID else {
          return Fail(error: FirebaseUserError.invalidUid).eraseToAnyPublisher()
        }
        
        // firestore fetch -> localDB save
        let publisher: AnyPublisher<DateTimeResponseDTO, any Error> = self.firebaseNetworkService.getDocument(
          documentPath: FirestorePath.userID(userID: userID)
        )
          .receive(on: self.backgroundQueue)
          .eraseToAnyPublisher()
        
        return publisher.tryMap { $0.toDomain() }
          .flatMap { dateTime in
            return self.dateTimeStorage
              .saveDateTime(dateTime: dateTime)
          }
          .eraseToAnyPublisher()
      }
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
    
    let requestDTO = DateTimeRequestDTO(date: date, hour: hour, minute: minute)
    let publisher: AnyPublisher<Void, any Error> = self.firebaseNetworkService.setDocument(
      documentPath: FirestorePath.userID(userID: userID),
      requestDTO: requestDTO,
      merge: true
    )
    
    return publisher
    .flatMap { [weak self] _ in
      guard let self else { return Empty<Void, any Error>().eraseToAnyPublisher() }
      let dateTime = DateTime(date: date, hour: hour, minute: minute)
      return self.dateTimeStorage.saveDateTime(dateTime: dateTime)
        .map { _ in }
        .eraseToAnyPublisher()
    }
    .receive(on: self.backgroundQueue)
    .eraseToAnyPublisher()
  }
}
