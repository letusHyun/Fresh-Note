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

protocol SignOutAlertViewModelOutput { }

final class DefaultSignOutAlertViewModel: SignOutAlertViewModel {
  // MARK: - Properties
  private var subscriptions: Set<AnyCancellable> = []
  private let actions: SignOutAlertViewModelActions
  
  // MARK: - Output
  
  // MARK: - LifeCycle
  init(actions: SignOutAlertViewModelActions) {
    self.actions = actions
  }
  
  // MARK: - Input
  func didTapCancelButton() {
    print("cancelButton tapped!")
    self.actions.pop()
  }
  
  func didTapSignOutButton() {
    print("signOutButton tapped!")
    self.actions.pop()
  }
}
