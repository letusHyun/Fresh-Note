//
//  PushNotiRestorationStateRepositoryMock.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import Combine
import Foundation

final class PushNotiRestorationStateRepositoryMock: PushNotiRestorationStateRepository {
  private(set) var saveRestoreStateCallCount = 0
  private(set) var fetchRestoreStateCallCount = 0
  private(set) var lastSavedRestorationState: PushNotiRestorationState?
  
  var saveRestoreStateResult: AnyPublisher<Void, any Error>!
  var fetchRestoreStateResult: AnyPublisher<PushNotiRestorationState, any Error>!
  
  func saveRestoreState(restorationState: PushNotiRestorationState) -> AnyPublisher<Void, any Error> {
    self.saveRestoreStateCallCount += 1
    self.lastSavedRestorationState = restorationState
    return self.saveRestoreStateResult
  }
  
  func fetchRestoreState() -> AnyPublisher<PushNotiRestorationState, any Error> {
    self.fetchRestoreStateCallCount += 1
    return self.fetchRestoreStateResult
  }
} 