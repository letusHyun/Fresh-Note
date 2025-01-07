//
//  CategoryDetailViewModel.swift
//  FreshNote
//
//  Created by SeokHyun on 1/7/25.
//

import Foundation

struct CategoryDetailViewModelActions {
  let pop: () -> Void
  let showProduct: (DocumentID) -> Void
}

protocol CategoryDetailViewModelInput {
  func viewDidLoad()
  func numberOfRowsInSection() -> Int
  func cellForItem(at indexPath: IndexPath) -> Product
}

protocol CategoryDetailViewModelOutput {
  
}

protocol CategoryDetailViewModel: CategoryDetailViewModelInput & CategoryDetailViewModelOutput { }

final class DefaultCategoryDetailViewModel: CategoryDetailViewModel {
  // MARK: - Properties
  private let actions: CategoryDetailViewModelActions
  private let fetchProductUseCase: any FetchProductUseCase
  private let updateProductUseCase: any UpdateProductUseCase
  private var dataSource: [Product] = []
  
  // MARK: - Output
  
  // MARK: - LifeCycle
  init(
    actions: CategoryDetailViewModelActions,
    fetchProductUseCase: any FetchProductUseCase,
    updateProductUseCase: any UpdateProductUseCase
  ) {
    self.actions = actions
    self.fetchProductUseCase = fetchProductUseCase
    self.updateProductUseCase = updateProductUseCase
  }
  
  
  // MARK: - Input
  func viewDidLoad() {
    
  }
  
  func numberOfRowsInSection() -> Int {
    self.dataSource.count
  }
  
  func cellForItem(at indexPath: IndexPath) -> Product {
    return self.dataSource[indexPath.row]
  }
}
