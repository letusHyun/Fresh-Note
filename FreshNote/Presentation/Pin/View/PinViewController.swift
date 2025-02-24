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
  private let activityIndicatorView = ActivityIndicatorView()
  
  private let viewModel: any PinViewModel
  
  private lazy var tableView: UITableView = {
    let tv = UITableView()
    tv.separatorStyle = .none
    tv.register(ProductCell.self, forCellReuseIdentifier: ProductCell.id)
    tv.dataSource = self
    tv.delegate = self
    return tv
  }()
  
  private var subscriptions: Set<AnyCancellable> = []
  
  private let pinEmptyView = EmptyIndicatorView(
    title: "고정된 상품이 없어요.",
    description: "내가 등록한 중요한 상품을 고정해주세요.",
    imageName: .system("pin")
  )
  
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
    defer { self.viewModel.viewDidLoad() }
    
    self.bind(to: self.viewModel)
    self.setupNavigationBar()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.activityIndicatorView.startIndicating()
    self.viewModel.viewWillAppear()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.activityIndicatorView.stopIndicating()
  }
  
  // MARK: - SetupUI
  override func setupLayout() {
    self.view.addSubview(self.tableView)
    self.view.addSubview(self.activityIndicatorView)
    
    self.tableView.snp.makeConstraints {
      $0.top.bottom.equalTo(self.view.safeAreaLayoutGuide)
      $0.leading.trailing.equalToSuperview()
    }
    
    self.activityIndicatorView.snp.makeConstraints {
      $0.top.bottom.equalTo(self.view.safeAreaLayoutGuide)
      $0.leading.trailing.equalToSuperview()
    }
  }
  
  // MARK: - Private
  private func bind(to viewModel: any PinViewModel) {
    self.viewModel
      .errorPublisher
      .compactMap { $0 }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] error in
        self?.activityIndicatorView.stopIndicating()
        // MARK: - Error Handling
      }
      .store(in: &self.subscriptions)
    
    self.viewModel
      .reloadDataPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.activityIndicatorView.stopIndicating()
        self?.tableView.reloadData()
        self?.updateEmptyViewVisibility()
      }
      .store(in: &self.subscriptions)
    
    self.viewModel
      .deleteRowsPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self]indexPath in
        self?.activityIndicatorView.stopIndicating()
        self?.tableView.deleteRows(at: [indexPath], with: .fade)
        self?.updateEmptyViewVisibility()
      }
      .store(in: &self.subscriptions)
  }
  
  private func setupNavigationBar() {
    self.navigationItem.title = "핀"
  }
  
  private func updateEmptyViewVisibility() {
    self.pinEmptyView.updateVisibility(
      shouldHidden: !self.viewModel.isDataSourceEmpty(),
      from: self.tableView
    )
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
    
    cell.delegate = self
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

extension PinViewController: ProductCellDelegate {
  func didTapPin(in cell: UITableViewCell) {
    guard let indexPath = self.tableView.indexPath(for: cell) else { return }
    
    self.activityIndicatorView.startIndicating()
    self.viewModel.didTapPin(at: indexPath)
  }
}
