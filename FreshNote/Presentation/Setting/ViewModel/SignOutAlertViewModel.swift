//
//  SignOutAlertViewModel.swift
//  FreshNote
//
//  Created by SeokHyun on 1/19/25.
//

import Combine
import Foundation

struct SignOutAlertViewModelActions {
  let dismissSignOutAlert: () -> Void
  let dismiss: () -> Void
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
  private let signOutUseCase: any SignOutUseCase
  
  // MARK: - Output
  var errorPublisher: AnyPublisher<(any Error)?, Never> { self.$error.eraseToAnyPublisher() }
  @Published private var error: (any Error)?
  
  // MARK: - LifeCycle
  init(
    actions: SignOutAlertViewModelActions,
    deleteCacheUseCase: any DeleteCacheUseCase,
    signOutUseCase: any SignOutUseCase
  ) {
    self.actions = actions
    self.deleteCacheUseCase = deleteCacheUseCase
    self.signOutUseCase = signOutUseCase
  }
  
  // MARK: - Input
  func didTapCancelButton() {
    self.actions.dismiss()
  }
  
  func didTapSignOutButton() {
    self.signOutUseCase
      .signOut()
      .flatMap { [weak self] _ -> AnyPublisher<Void, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        
        return self.signOutUseCase.saveRestorationState()
      }
      .flatMap { [weak self] _ -> AnyPublisher<Void, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        
        return self.deleteCacheUseCase.execute()
      }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] completion in
        guard case .failure(let error) = completion else { return }
        self?.error = error
      } receiveValue: { [weak self] _ in
        self?.actions.dismissSignOutAlert()
      }
      .store(in: &self.subscriptions)
  }
}
