//
//  CategoryBottomSheetViewModel.swift
//  FreshNote
//
//  Created by SeokHyun on 11/23/24.
//

import Foundation

struct CategoryBottomSheetViewModelActions {
  let passCategory: (String) -> Void
}

typealias CategoryBottomSheetViewModel = CategoryBottomSheetViewModelInput & CategoryBottomSheetViewModelOutput

protocol CategoryBottomSheetViewModelInput {
  func numberOfRowsInSection() -> Int
  func cellForRow(at indexPath: IndexPath) -> String
  func didSelectRow(at: IndexPath)
}

protocol CategoryBottomSheetViewModelOutput {
  
}

final class DefaultCategoryBottomSheetViewModel: CategoryBottomSheetViewModel {
  // MARK: - Properties
  private let categories: [String]
  private let actions: CategoryBottomSheetViewModelActions
  
  // MARK: - Output
  
  // MARK: - LifeCycle
  init(actions: CategoryBottomSheetViewModelActions) {
    self.actions = actions
    self.categories = ProductCategory.allCases.map { $0.rawValue }
  }
  
  // MARK: - Input
  func numberOfRowsInSection() -> Int {
    return self.categories.count
  }
  
  func cellForRow(at indexPath: IndexPath) -> String {
    return self.categories[indexPath.item]
  }
  
  func didSelectRow(at indexPath: IndexPath) {
    let category = self.categories[indexPath.row]
    self.actions.passCategory(category)
  }
}
