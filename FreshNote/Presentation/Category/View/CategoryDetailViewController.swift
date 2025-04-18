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
  
  private let activityIndicatorView = ActivityIndicatorView()
  
  
  private lazy var emptyIndicatorView: EmptyIndicatorView = {
    let categoryName: String = self.navigationItem.title ?? ""
    let title: String = "\(categoryName)에 제품이 없어요."
    let emptyIndicatorView = EmptyIndicatorView(
      title: title,
      description: "제품 등록 시 카테고리를 설정해보세요.",
      imageName: .system("list.dash")
    )
    return emptyIndicatorView
  }()
  
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
    defer { self.viewModel.viewDidLoad() }
    
    self.bind(to: self.viewModel)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    self.viewModel.viewWillAppear()
  }
  
  deinit {
    print("DEBUG: \(Self.self) deinit")
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
  private func bind(to viewModel: any CategoryDetailViewModel) {
    viewModel.reloadDataPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in
        self?.activityIndicatorView.stopIndicating()
        self?.tableView.reloadData()
        self?.updateEmptyViewVisibility()
      }
      .store(in: &self.subscriptions)
    
    viewModel.errorPublisher
      .receive(on: DispatchQueue.main)
      .compactMap { $0 }
      .sink { [weak self] error in
        self?.activityIndicatorView.stopIndicating()
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
        self?.activityIndicatorView.stopIndicating()
        guard let cell = self?.tableView.cellForRow(at: indexPath) as? ProductCell else { return }
        
        cell.configurePin(isPinned: updatedPinState)
      }
      .store(in: &self.subscriptions)
  }
  
  private func updateEmptyViewVisibility() {
    self.emptyIndicatorView.updateVisibility(
      shouldHidden: !self.viewModel.isDataSourceEmpty(),
      from: self.tableView
    )
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
    
    self.activityIndicatorView.startIndicating()
    self.viewModel.didTapPin(at: indexPath)
  }
}
