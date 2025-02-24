//
//  NotificationViewController.swift
//  FreshNote
//
//  Created by SeokHyun on 10/31/24.
//

import UIKit
import Combine

final class NotificationViewController: BaseViewController {
  // MARK: - Properties
  private let viewModel: any NotificationViewModel
  
  private let tableView: UITableView = {
    let tv = UITableView(frame: .zero, style: .plain)
    tv.rowHeight = 60
    tv.register(NotificationCell.self, forCellReuseIdentifier: NotificationCell.id)
    return tv
  }()
  
  private var subscriptions = Set<AnyCancellable>()
  
  private let backButton = NavigationBackButton()
  
  // MARK: - LifeCycle
  init(viewModel: any NotificationViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }
  
  @MainActor required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupTableView()
    setupNavigationBar()
    bindActions()
    bind(to: self.viewModel)
    viewModel.viewDidLoad()
  }
  
  // MARK: - SetupUI
  override func setupLayout() {
    view.addSubview(tableView)
    
    tableView.translatesAutoresizingMaskIntoConstraints = false
    
    let safeArea = view.safeAreaLayoutGuide
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: safeArea.topAnchor),
      tableView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
    ])
  }
}

// MARK: - Private Helpers
extension NotificationViewController {
  private func setupNavigationBar() {
    let titleLabel: UILabel = {
      let lb = UILabel()
      lb.text = "알림"
      lb.font = UIFont.pretendard(size: 20, weight: ._500)
      return lb
    }()
    navigationItem.titleView = titleLabel
    navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
  }
  
  private func setupTableView() {
    tableView.dataSource = self
    tableView.delegate = self
  }
  
  private func bind(to viewModel: NotificationViewModel) {
    viewModel.reloadDataPublisher.sink { [weak self] _ in
      self?.tableView.reloadData()
    }
    .store(in: &subscriptions)
    
    viewModel.reloadRowPublisher.sink { [weak self] indexPath in
      self?.tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    .store(in: &subscriptions)
  }
}

// MARK: - UITableViewDataSource
extension NotificationViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.numberOfRowsInSection()
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(
      withIdentifier: NotificationCell.id
    ) as? NotificationCell else { return UITableViewCell() }
    
    let notification = viewModel.cellForRow(at: indexPath)
    cell.configure(notification: notification)
    
    return cell
  }
}

// MARK: - UITableViewDelegate
extension NotificationViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    cell.selectionStyle = .none
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    viewModel.didSelectRow(at: indexPath)
  }
}

// MARK: - Actions
private extension NotificationViewController {
  func bindActions() {
    self.backButton.tapPublisher
      .sink { [weak self] _ in
        self?.viewModel.didTapBackButton()
      }
      .store(in: &subscriptions)
  }
}
