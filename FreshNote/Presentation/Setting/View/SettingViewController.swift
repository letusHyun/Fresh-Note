//
//  SettingViewController.swift
//  FreshNote
//
//  Created by SeokHyun on 1/16/25.
//

import Combine
import Foundation
import UIKit

import SnapKit

final class SettingViewController: BaseViewController {
  // MARK: - Properties
  private let viewModel: any SettingViewModel
  
  private lazy var tableView: UITableView = {
    let tv = UITableView(frame: .zero)
    tv.register(SettingCell.self, forCellReuseIdentifier: SettingCell.id)
    tv.register(SettingHeaderView.self, forHeaderFooterViewReuseIdentifier: SettingHeaderView.id)
    tv.register(SettingEmptyView.self, forHeaderFooterViewReuseIdentifier: SettingEmptyView.id)
    tv.dataSource = self
    tv.delegate = self
    tv.separatorStyle = .none
    tv.bounces = false
    return tv
  }()
  
  // MARK: - LifeCycle
  init(viewModel: any SettingViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }
  
  @MainActor required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    defer { self.viewModel.viewDidLoad() }
    self.setupNavigationBar()
    self.bind(to: viewModel)
  }
  
  // MARK: - Bind
  private func bind(to viewModel: any SettingViewModel) {
    
  }
  
  // MARK: - SetupUI
  override func setupLayout() {
    self.view.addSubview(self.tableView)
    
    self.tableView.snp.makeConstraints {
      $0.top.bottom.equalTo(self.view.safeAreaLayoutGuide)
      $0.leading.trailing.equalToSuperview()
    }
  }
  
  // MARK: - Private
  private func setupNavigationBar() {
    self.navigationItem.title = "마이"
    self.navigationItem.backButtonDisplayMode = .minimal
  }
}


// MARK: - UITableViewDataSource
extension SettingViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    self.viewModel.numberOfRows(in: section)
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(
      withIdentifier: SettingCell.id,
      for: indexPath
    ) as? SettingCell else { return UITableViewCell() }
    
    let title = self.viewModel.cellForItem(at: indexPath)
    cell.configure(with: title)
    return cell
  }
  
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard let headerView = tableView.dequeueReusableHeaderFooterView(
      withIdentifier: SettingHeaderView.id
    ) as? SettingHeaderView else { return nil }
    
    let headerTitle = self.viewModel.viewForHeader(in: section)
    headerView.configure(with: headerTitle)
    
    return headerView
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    self.viewModel.numberOfSections()
  }
  
  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    guard let footerView = tableView.dequeueReusableHeaderFooterView(
      withIdentifier: SettingEmptyView.id
    ) as? SettingEmptyView else { return nil }
    
    return footerView
  }
}

// MARK: - UITableViewDelegate
extension SettingViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    self.viewModel.didSelectRow(at: indexPath)
  }
  
  
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    60
  }
  
  func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    self.viewModel.heightForFooter(in: section)
  }
}
