//
//  AccountDeletionViewModel.swift
//  FreshNote
//
//  Created by SeokHyun on 1/23/25.
//

import Foundation

struct AccountDeletionViewModelActions {
  let pop: () -> Void
}

protocol AccountDeletionViewModelOutput {
  
}

protocol AccountDeletionViewModelInput {
  
}

protocol AccountDeletionViewModel: AccountDeletionViewModelInput & AccountDeletionViewModelOutput { }

final class DefaultAccountDeletionViewModel: AccountDeletionViewModel {
  // MARK: - Properties
  private let actions: AccountDeletionViewModelActions
  
  // MARK: - Output
  
  // MARK: - LifeCycle
  init(actions: AccountDeletionViewModelActions) {
    self.actions = actions
  }
  
  // MARK: - Input
}
