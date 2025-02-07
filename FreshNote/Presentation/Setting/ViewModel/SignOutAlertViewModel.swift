//
//  SignOutAlertViewModel.swift
//  FreshNote
//
//  Created by SeokHyun on 1/19/25.
//

import Combine
import Foundation

struct SignOutAlertViewModelActions {
  let pop: () -> Void
}

protocol SignOutAlertViewModel: SignOutAlertViewModelInput, SignOutAlertViewModelOutput { }

protocol SignOutAlertViewModelInput {
  func didTapCancelButton()
  func didTapSignOutButton()
}

protocol SignOutAlertViewModelOutput {
  var errorPublisher: AnyPublisher<(any Error)?, Never> { get }
}

final class DefaultSignOutAlertViewModel: SignOutAlertViewModel {
  // MARK: - Properties
  private var subscriptions: Set<AnyCancellable> = []
  private let actions: SignOutAlertViewModelActions
  private let deleteCacheUseCase: any DeleteCacheUseCase
  
  // MARK: - Output
  var errorPublisher: AnyPublisher<(any Error)?, Never> { self.$error.eraseToAnyPublisher() }
  @Published private var error: (any Error)?
  
  // MARK: - LifeCycle
  init(
    actions: SignOutAlertViewModelActions,
    deleteCacheUseCase: any DeleteCacheUseCase
  ) {
    self.actions = actions
    self.deleteCacheUseCase = deleteCacheUseCase
  }
  
  // MARK: - Input
  func didTapCancelButton() {
    print("cancelButton tapped!")
    self.actions.pop()
  }
  
  func didTapSignOutButton() {
    self.deleteCacheUseCase
      .execute()
      .sink { [weak self] completion in
        guard case .failure(let error) = completion else { return }
        self?.error = error
      } receiveValue: { [weak self] _ in
        
        // 1. firebase signOut
        // 2. 알림 삭제, coredata 삭제, useDefaults
        self?.actions.pop()
      }
      .store(in: &self.subscriptions)

    
  }
}
