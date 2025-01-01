//
//  PinViewController.swift
//  FreshNote
//
//  Created by SeokHyun on 12/31/24.
//

import Combine
import UIKit

import SnapKit

final class PinViewController: BaseViewController {
  // MARK: - Properties
  private let viewModel: any PinViewModel
  private lazy var tableView: UITableView = {
    let tv = UITableView()
    tv.register(ProductCell.self, forCellReuseIdentifier: ProductCell.id)
    tv.dataSource = self
    tv.delegate = self
    return tv
  }()
  
  // MARK: - LifeCycle
  init(viewModel: any PinViewModel) {
    self.viewModel = viewModel
    
    super.init(nibName: nil, bundle: nil)
  }
  
  @MainActor required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
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
  private func bind(to viewModel: any PinViewModel) {
    
  }
}

// MARK: - UITableViewDataSource
extension PinViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.numberOfRowsInSection()
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: ProductCell.id) as? ProductCell
    else {return UITableViewCell() }
    
    let product = self.viewModel.cellForRow(at: indexPath)
    cell.configure(product: product)
    
    return cell
  }
}

// MARK: - UITableViewDelegate
extension PinViewController: UITableViewDelegate {
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
