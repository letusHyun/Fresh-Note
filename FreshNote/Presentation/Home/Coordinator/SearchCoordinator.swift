//
//  SearchCoordinator.swift
//  FreshNote
//
//  Created by SeokHyun on 11/1/24.
//

import UIKit

protocol SearchCoordinatorDependencies: AnyObject {
  func makeSearchViewController(actions: SearchViewModelActions) -> SearchViewController
}

final class SearchCoordinator: BaseCoordinator {
  // MARK: - Properties
  private let dependencies: any SearchCoordinatorDependencies
  
  // MARK: - LifeCycle
  init(
    dependencies: any SearchCoordinatorDependencies,
    navigationController: UINavigationController?
  ) {
    self.dependencies = dependencies
    super.init(navigationController: navigationController)
  }
  
  deinit {
    print("DEBUG: \(Self.self) deinit")
  }
}

// MARK: - Start
extension SearchCoordinator {
  func start() {
    // TODO: - make actions
    let actions = SearchViewModelActions(pop: { [weak self] in
      self?.pop()
    })
    let viewController = self.dependencies.makeSearchViewController(actions: actions)
    self.navigationController?.pushViewController(viewController, animated: true)
  }
}

// MARK: - Private Helpers
extension SearchCoordinator {
  private func pop() {
    self.navigationController?.popViewController(animated: true)
    self.finish()
  }
}
