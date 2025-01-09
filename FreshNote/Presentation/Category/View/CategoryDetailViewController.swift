//
//  CategoryDetailViewController.swift
//  FreshNote
//
//  Created by SeokHyun on 1/7/25.
//

import Combine
import UIKit

import SnapKit

final class CategoryDetailViewController: BaseViewController {
  // MARK: - Properties
  private let viewModel: any CategoryDetailViewModel
  
  private lazy var tableView: UITableView = {
    let tv = UITableView()
    tv.register(ProductCell.self, forCellReuseIdentifier: ProductCell.id)
    tv.dataSource = self
    tv.delegate = self
    tv.separatorStyle = .none
    return tv
  }()
  
  private var subscriptions: Set<AnyCancellable> = []
  
  // MARK: - LifeCycle
  init(viewModel: any CategoryDetailViewModel) {
    self.viewModel = viewModel
    
    super.init(nibName: nil, bundle: nil)
  }
  
  @MainActor required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    
    defer { self.viewModel.viewDidLoad() }
    
    self.bind(to: self.viewModel)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    self.viewModel.viewWillAppear()
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
  private func bind(to viewModel: any CategoryDetailViewModel) {
    viewModel.reloadDataPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in
        ActivityIndicatorView.shared.stopIndicating()
        
        self?.tableView.reloadData()
      }
      .store(in: &self.subscriptions)
    
    viewModel.errorPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] error in
        guard let error = error else { return }
        ActivityIndicatorView.shared.stopIndicating()
        // TODO: - Error handling
      }
      .store(in: &self.subscriptions)
    
    viewModel.configureTitlePublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] title in
        self?.navigationItem.title = title
      }
      .store(in: &self.subscriptions)
    
    viewModel.updatePinPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] indexPath, updatedPinState in
        ActivityIndicatorView.shared.stopIndicating()
        guard
          let self,
          let cell = self.tableView.cellForRow(at: indexPath) as? ProductCell
        else { return }
        
        cell.configurePin(isPinned: updatedPinState)
      }
      .store(in: &self.subscriptions)
  }
}

// MARK: - UITableViewDataSource
extension CategoryDetailViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.numberOfRowsInSection()
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(
      withIdentifier: ProductCell.id,
      for: indexPath
    ) as? ProductCell else { return UITableViewCell() }
    
    let product = self.viewModel.cellForItem(at: indexPath)
    cell.delegate = self
    cell.configure(product: product)
    
    return cell
  }
}

// MARK: - UITableViewDelegate
extension CategoryDetailViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 100
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    self.viewModel.didSelectRow(at: indexPath)
  }
  
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    cell.selectionStyle = .none
  }
}

// MARK: - ProductCellDelegate
extension CategoryDetailViewController: ProductCellDelegate {
  func didTapPin(in cell: UITableViewCell) {
    guard let indexPath = self.tableView.indexPath(for: cell) else { return }
    
    ActivityIndicatorView.shared.startIndicating()
    self.viewModel.didTapPin(at: indexPath)
  }
}
