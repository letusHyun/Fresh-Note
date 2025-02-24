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
  
  /// fetchDateTime으로 하는데, storage에 존재하면 가져오고, 없으면 firestore에서 가져오기
  func fetchDateTime() -> AnyPublisher<DateTime, any Error> {
    self.dateTimeStorage
      .fetchDateTime()
      .catch { [weak self] error -> AnyPublisher<DateTime, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        
        guard case CoreDataStorageError.readError(let wrappedError) = error,
              case CoreDataStorageError.noEntity = wrappedError else {
          return Fail(error: error).eraseToAnyPublisher()
        }
        
        // storage에 존재하지 않으면 firestore에서 가져오기
        
        guard let userID = FirebaseUserManager.shared.userID else {
          return Fail(error: FirebaseUserError.invalidUid).eraseToAnyPublisher()
        }
        // storage에 dateTime이 존재하지 않는다면
        // firestore fetch -> localDB save
        let publisher: AnyPublisher<DateTimeResponseDTO, any Error> = self.firebaseNetworkService.getDocument(
          documentPath: FirestorePath.userID(userID: userID)
        )
          .eraseToAnyPublisher()
        
        return publisher.map { $0.toDomain() }
          .flatMap { dateTime in
            return self.dateTimeStorage
              .saveDateTime(dateTime: dateTime)
          }
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
  
  // 앱 시작 -> refresh token 존재 o -> 로그아웃 상태 x -> 이 메소드의 value가
  // true인 경우: 메인 홈 화면 이동
  // false인 경우: 날짜 설정 화면 이동
  func isSavedDateTime() -> AnyPublisher<Bool, any Error> {
    return self.fetchDateTime()
      .map { _ in return true }
      .catch { error -> AnyPublisher<Bool, any Error> in
        // firestore에 데이터가 저장되어있지 않으면 false
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
  
  /// 1. api save, 2. cache save
  func saveDateTime(dateTime: DateTime) -> AnyPublisher<Void, any Error> {
    let publisher = self.requestDateTimeFromFireBase(dateTime: dateTime)
    
    return publisher
      .flatMap { [weak self] _ in
        guard let self else {
          return Fail<Void, any Error>(error: CommonError.referenceError).eraseToAnyPublisher()
        }
        
        return self.dateTimeStorage
          .saveDateTime(dateTime: dateTime)
          .map { _ in }
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
  
  func updateDateTime(dateTime: DateTime) -> AnyPublisher<Void, any Error> {
    // 1. firebase
    let publisher = self.requestDateTimeFromFireBase(dateTime: dateTime)
    
    return publisher
      .flatMap { [weak self] _ in
        guard let self else {
          return Fail<Void, any Error>(error: CommonError.referenceError).eraseToAnyPublisher()
        }
        
        // 2. storage
        return self.dateTimeStorage
          .updateDateTime(dateTime: dateTime)
          .map { _ in }
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
  
  func deleteCachedDateTime() -> AnyPublisher<Void, any Error> {
    self.dateTimeStorage
      .deleteDateTime()
  }
  
  // MARK: - Private
  
  /// save 및 update
  private func requestDateTimeFromFireBase(dateTime: DateTime) -> AnyPublisher<Void, any Error> {
    guard let userID = FirebaseUserManager.shared.userID
    else { return Fail(error: FirebaseUserError.invalidUid).eraseToAnyPublisher() }
    
    let requestDTO = DateTimeRequestDTO(date: dateTime.date, hour: dateTime.hour, minute: dateTime.minute)
    let publisher: AnyPublisher<Void, any Error> = self.firebaseNetworkService.setDocument(
      documentPath: FirestorePath.userID(userID: userID),
      requestDTO: requestDTO,
      merge: true
    )
    
    return publisher
  }
}
