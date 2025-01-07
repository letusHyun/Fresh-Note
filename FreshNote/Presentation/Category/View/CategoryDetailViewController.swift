//
//  CategoryDetailViewController.swift
//  FreshNote
//
//  Created by SeokHyun on 1/7/25.
//

import UIKit

final class CategoryDetailViewController: BaseViewController {
  // MARK: - Properties
  private let viewModel: any CategoryDetailViewModel
  
  private lazy var tableView: UITableView = {
    let tv = UITableView()
    tv.register(ProductCell.self, forCellReuseIdentifier: ProductCell.id)
    tv.dataSource = self
    tv.delegate = self
    return tv
  }()
  
  // MARK: - LifeCycle
  init(viewModel: any CategoryDetailViewModel) {
    self.viewModel = viewModel
    
    super.init(nibName: nil, bundle: nil)
  }
  
  @MainActor required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - UITableViewDataSource
extension CategoryDetailViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.numberOfRowsInSection()
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    self.viewModel.cellForItem(at: indexPath)
  }
}

// MARK: - UITableViewDelegate
extension CategoryDetailViewController: UITableViewDelegate {
  
}
