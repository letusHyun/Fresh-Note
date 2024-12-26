//
//  HomeViewController.swift
//  FreshNote
//
//  Created by SeokHyun on 10/23/24.
//

import UIKit
import Combine

import SnapKit

final class HomeViewController: BaseViewController {
  // MARK: - Properties
  private let viewModel: any HomeViewModel
  
  private let tableView: UITableView = {
    let tv = UITableView(frame: .zero)
    tv.register(ProductCell.self, forCellReuseIdentifier: ProductCell.id)
    tv.separatorStyle = .none
    return tv
  }()
  
  private var subscriptions = Set<AnyCancellable>()
  
  private let searchButton: UIButton = {
    let btn = UIButton()
    let image = UIImage(systemName: "magnifyingglass")?
      .resized(to: CGSize(width: 27, height: 27))
    btn.setImage(image, for: .normal)
    return btn
  }()
  
  private let addProductButton: UIButton = {
    let btn = UIButton()
    let image = UIImage(systemName: "plus")?
      .resized(to: CGSize(width: 27, height: 27))
    btn.setImage(image, for: .normal)
    return btn
  }()
  
  private let notificationButton: UIButton = {
    let btn = UIButton()
    let image = UIImage(systemName: "bell")?
      .resized(to: CGSize(width: 27, height: 27))
    btn.setImage(image, for: .normal)
    return btn
  }()
  
  // MARK: - LifeCycle
  init(viewModel: any HomeViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    ActivityIndicatorView.shared.startIndicating()
    self.setupTableView()
    self.setNavigationBar()
    self.bindActions()
    self.bind(to: self.viewModel)
    self.viewModel.viewDidLoad()
  }
  
  override func setupLayout() {
    self.view.addSubview(self.tableView)
    
    self.tableView.snp.makeConstraints {
      $0.leading.trailing.equalToSuperview()
      $0.top.equalTo(self.view.safeAreaLayoutGuide)
      $0.bottom.equalTo(self.view.safeAreaLayoutGuide)
    }
    

  }
}

// MARK: - Private Helpers
extension HomeViewController {
  private func setupTableView() {
    self.tableView.dataSource = self
    self.tableView.delegate = self
  }
  
  private func setNavigationBar() {
    navigationItem.leftBarButtonItem = UIBarButtonItem(customView: self.notificationButton)
    let rightBarButtonItems = [self.addProductButton, self.searchButton].map { UIBarButtonItem(customView: $0) }
    navigationItem.rightBarButtonItems = rightBarButtonItems
    navigationItem.titleView = FreshNoteTitleView()
  }
  
  private func bind(to viewModel: any HomeViewModel) {
    viewModel.errorPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] error in
        // TODO: - 에러 UI 처리하기
        ActivityIndicatorView.shared.stopIndicating()
        print("error발생: \(error?.localizedDescription)")
      }
      .store(in: &self.subscriptions)
    
    viewModel.reloadDataPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in
        ActivityIndicatorView.shared.stopIndicating()
        self?.tableView.reloadData()
      }
      .store(in: &self.subscriptions)
    
    viewModel.deleteRowsPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] indexPaths, swipeCompletion in
        ActivityIndicatorView.shared.stopIndicating()
        self?.tableView.deleteRows(at: indexPaths, with: .fade)
        swipeCompletion(true)
      }.store(in: &self.subscriptions)
    
    viewModel.reloadRowsPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] indexPaths in
        ActivityIndicatorView.shared.stopIndicating()
        self?.tableView.reloadRows(at: indexPaths, with: .automatic)
      }
      .store(in: &self.subscriptions)
  }
}

// MARK: - UITableViewDataSource
extension HomeViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    self.viewModel.numberOfItemsInSection()
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(
      withIdentifier: ProductCell.id,
      for: indexPath
    ) as? ProductCell else { return UITableViewCell() }
    
    let product = self.viewModel.cellForItemAt(indexPath: indexPath)
    cell.configure(product: product)
    
    return cell
  }
}

// MARK: - UITableViewDelegate
extension HomeViewController: UITableViewDelegate {
  func tableView(
    _ tableView: UITableView,
    trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
  ) -> UISwipeActionsConfiguration? {
    let deleteAction = UIContextualAction(
      style: .destructive,
      title: "삭제"
    ) { [weak self] (action, view, completionHandler) in
      ActivityIndicatorView.shared.startIndicating()
      self?.viewModel.trailingSwipeActionsConfigurationForRowAt(
        indexPath: indexPath,
        handler: completionHandler
      )
    }
    
    return UISwipeActionsConfiguration(actions: [deleteAction])
  }
  
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    cell.selectionStyle = .none
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 100
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    self.viewModel.didSelectRow(at: indexPath)
  }
}

// MARK: - Actions
private extension HomeViewController {
  func bindActions() {
    self.notificationButton.publisher(for: .touchUpInside)
      .sink { [weak self] _ in
        self?.viewModel.didTapNotificationButton()
      }
      .store(in: &self.subscriptions)
    
    self.searchButton.publisher(for: .touchUpInside)
      .sink { [weak self] _ in
        self?.viewModel.didTapSearchButton()
      }
      .store(in: &self.subscriptions)
    
    self.addProductButton.publisher(for: .touchUpInside)
      .sink { [weak self] _ in
        self?.viewModel.didTapAddProductButton()
      }
      .store(in: &self.subscriptions)
  }
}
