//
//  CategoryViewController.swift
//  FreshNote
//
//  Created by SeokHyun on 1/7/25.
//

import Combine
import UIKit

import SnapKit

final class CategoryViewController: BaseViewController {
  // MARK: - Properties
  private let viewModel: any CategoryViewModel
  
  private lazy var tableView: UITableView = {
    let tv = UITableView()
    tv.delegate = self
    tv.dataSource = self
    tv.rowHeight = 50
    tv.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.id)
    return tv
  }()
  
  private var subscriptions: Set<AnyCancellable> = []
  
  // MARK: - LifeCycle
  init(viewModel: any CategoryViewModel) {
    self.viewModel = viewModel
    
    super.init(nibName: nil, bundle: nil)
  }
  
  @MainActor required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.bind(to: self.viewModel)
    self.setupNavigationBar()
  }
  
  // MARK: - SetupUI
  override func setupLayout() {
    self.view.addSubview(self.tableView)
    
    self.tableView.snp.makeConstraints {
      $0.top.bottom.equalTo(self.view.safeAreaLayoutGuide)
      $0.leading.trailing.equalToSuperview().inset(3)
    }
  }
  
  // MARK: - Private
  private func setupNavigationBar() {
    self.navigationItem.title = "카테고리"
  }
  
  private func bind(to viewModel: any CategoryViewModel) {
    
  }
}

// MARK: - UITableViewDataSource
extension CategoryViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    self.viewModel.numberOfRowsInSection()
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: CategoryCell.id) as? CategoryCell
    else { return UITableViewCell() }
    
    let category = self.viewModel.cellForRow(at: indexPath)
    cell.configure(text: category)
    
    return cell
  }
}

// MARK: - UITableViewDelegate
extension CategoryViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    self.viewModel.didSelectRow(at: indexPath)
  }
}
