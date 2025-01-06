//
//  CategoryViewModel.swift
//  FreshNote
//
//  Created by SeokHyun on 1/7/25.
//

import Foundation

struct CategoryViewModelActions {
  let showCategoryDetail: (ProductCategory) -> Void
}

protocol CategoryViewModelInput {
  func viewDidLoad()
  func numberOfRowsInSection() -> Int
  func cellForRow(at indexPath: IndexPath) -> String
  func didSelectRow(at indexPath: IndexPath)
}

protocol CategoryViewModelOutput {
  
}

protocol CategoryViewModel: CategoryViewModelInput & CategoryViewModelOutput { }

final class DefaultCategoryViewModel: CategoryViewModel {
  // MARK: - Properties
  private let categories: [ProductCategory]
  private let actions: CategoryViewModelActions
  
  // MARK: - Output
  
  // MARK: - LifeCycle
  init(actions: CategoryViewModelActions) {
    self.categories = ProductCategory.allCases
    self.actions = actions
  }
  
  // MARK: - Input
  func viewDidLoad() {
    
  }
  
  func numberOfRowsInSection() -> Int {
    return self.categories.count
  }
  
  func cellForRow(at indexPath: IndexPath) -> String {
    return self.categories[indexPath.row].rawValue
  }
  
  func didSelectRow(at indexPath: IndexPath) {
    let category = self.categories[indexPath.row]
    self.actions.showCategoryDetail(category)
  }
}
