//
//  SearchResultView.swift
//  FreshNote
//
//  Created by SeokHyun on 1/9/25.
//

import Combine
import UIKit

import SnapKit

final class SearchResultView: UIView {
  typealias SearchResultViewModel = SearchResultViewModelInput & SearchResultViewModelOutput
  
  // MARK: - Properties
  private let activityIndicatorView = ActivityIndicatorView()
  
  private lazy var tableView: UITableView = {
    let tv = UITableView()
    tv.separatorStyle = .none
    tv.register(ProductCell.self, forCellReuseIdentifier: ProductCell.id)
    tv.dataSource = self
    tv.delegate = self
    return tv
  }()
  
  private let viewModel: any SearchResultViewModel
  
  private var subscriptions: Set<AnyCancellable> = []
  
  // MARK: - LifeCycle
  init(viewModel: any SearchResultViewModel) {
    self.viewModel = viewModel
    
    super.init(frame: .zero)
    self.setupUI()
    bind(to: self.viewModel)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Bind
  private func bind(to viewModel: any SearchResultViewModel) {
    viewModel.resultReloadDataPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in
        self?.activityIndicatorView.stopIndicating()
        self?.tableView.reloadData()
      }
      .store(in: &self.subscriptions)
    
    viewModel.resultErrorPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] error in
        guard let error = error else { return }
        print("SearchResultView error 발생: \(error)")
        self?.activityIndicatorView.stopIndicating()
      }
      .store(in: &self.subscriptions)
    
    viewModel.updatePinPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] indexPath, updatedPinState in
        self?.activityIndicatorView.stopIndicating()
        guard
          let self,
          let cell = self.tableView.cellForRow(at: indexPath) as? ProductCell
        else { return }
        
        cell.configurePin(isPinned: updatedPinState)
      }
      .store(in: &self.subscriptions)
  }
  
  // MARK: - Private
  private func setupUI() {
    self.setupLayout()
  }
  
  private func setupLayout() {
    self.addSubview(self.tableView)
    
    self.tableView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
  }
}

// MARK: - UITableViewDataSource
extension SearchResultView: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.resultNumberOfRowsInSection()
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(
      withIdentifier: ProductCell.id,
      for: indexPath
    ) as? ProductCell else { return UITableViewCell() }
    
    cell.delegate = self
    let product = self.viewModel.cellForRow(at: indexPath)
    cell.configure(product: product)
    
    return cell
  }
}

// MARK: - UITableViewDelegate
extension SearchResultView: UITableViewDelegate {
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    cell.selectionStyle = .none
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 100
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    self.viewModel.resultDidSelectRow(at: indexPath)
  }
}

// MARK: - ProductCellDelegate
extension SearchResultView: ProductCellDelegate {
  func didTapPin(in cell: UITableViewCell) {
    guard let indexPath = self.tableView.indexPath(for: cell) else { return }
    
    self.activityIndicatorView.startIndicating()
    self.viewModel.didTapPin(at: indexPath)
  }
}
