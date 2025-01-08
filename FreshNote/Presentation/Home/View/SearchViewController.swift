//
//  SearchViewController.swift
//  FreshNote
//
//  Created by SeokHyun on 11/1/24.
//

import UIKit
import Combine

final class SearchViewController: BaseViewController {
  // MARK: - Properties
  private let tableView: UITableView = {
    let tb = UITableView()
    tb.rowHeight = 60
    tb.register(
      RecentSearchKeywordCell.self,
      forCellReuseIdentifier: RecentSearchKeywordCell.id
    )
    return tb
  }()
  
  private let textField: PaddingTextField = {
    let tf = PaddingTextField()
    tf.layer.borderColor = UIColor(fnColor: .orange2).cgColor
    tf.layer.borderWidth = 0.8
    tf.layer.cornerRadius = 3
    let placeholderAttr = NSAttributedString(
      string: "상품명, 카테고리, 메모를 검색해주세요.",
      attributes: [
        NSAttributedString.Key.font: UIFont.pretendard(size: 12, weight: ._400),
        NSAttributedString.Key.foregroundColor: UIColor(fnColor: .gray1)
      ]
    )
    tf.attributedPlaceholder = placeholderAttr
    return tf
  }()
  
  private let cancelButton: UIButton = {
    let btn = UIButton()
    btn.setTitle("취소", for: .normal)
    btn.titleLabel?.font = UIFont.pretendard(size: 15, weight: ._400)
    btn.setTitleColor(UIColor(fnColor: .gray2), for: .normal)
    return btn
  }()
  
  private let viewModel: any SearchViewModel
  private var subscriptions: Set<AnyCancellable> = []
  
  // MARK: - LifeCycle
  init(viewModel: any SearchViewModel) {
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
    self.setupTableView()
    self.addTargets()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: true)
    tabBarController?.tabBar.isHidden = true
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.setNavigationBarHidden(false, animated: true)
    tabBarController?.tabBar.isHidden = false
  }
  
  // MARK: - SetupUI
  override func setupLayout() {
    let descriptionLabel = self.makeDescriptionLabel()
    
    view.addSubview(self.textField)
    view.addSubview(self.cancelButton)
    view.addSubview(descriptionLabel)
    view.addSubview(self.tableView)
    
    self.textField.translatesAutoresizingMaskIntoConstraints = false
    self.cancelButton.translatesAutoresizingMaskIntoConstraints = false
    descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
    self.tableView.translatesAutoresizingMaskIntoConstraints = false
  
    NSLayoutConstraint.activate([
      self.textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
      self.textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
      self.textField.heightAnchor.constraint(equalToConstant: 40)
    ] + [
      self.cancelButton.leadingAnchor.constraint(equalTo: self.textField.trailingAnchor, constant: 10),
      self.cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
      self.cancelButton.centerYAnchor.constraint(equalTo: self.textField.centerYAnchor),
      self.cancelButton.widthAnchor.constraint(equalToConstant: 33),
      self.cancelButton.heightAnchor.constraint(equalTo: self.textField.heightAnchor)
    ])
    
    NSLayoutConstraint.activate([
      descriptionLabel.topAnchor.constraint(equalTo: self.textField.bottomAnchor, constant: 15),
      descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
    ] + [
      self.tableView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 15),
      self.tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      self.tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      self.tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
  }
}

// MARK: - Private Helpers
extension SearchViewController {
  private func makeDescriptionLabel() -> UILabel {
    let lb = UILabel()
    lb.font = UIFont.pretendard(size: 12, weight: ._400)
    lb.text = "최근 검색어"
    lb.textColor = UIColor(fnColor: .gray2)
    return lb
  }
  
  private func addTargets() {
    self.cancelButton.addTarget(self, action: #selector(self.cancelButtonTapped), for: .touchUpInside)
  }
  
  private func setupTableView() {
    self.tableView.dataSource = self
    self.tableView.delegate = self
  }
}

// MARK: - Bind
private extension SearchViewController {
  func bind(to viewModel: any SearchViewModel) {
    viewModel.reloadDataPublisher.sink { [weak self] _ in
      self?.tableView.reloadData()
    }
    .store(in: &self.subscriptions)
    
    viewModel.deleteRowsPublisher.sink { [weak self] indexPath in
      self?.tableView.deleteRows(at: [indexPath], with: .fade)
    }
    .store(in: &self.subscriptions)
  }
}

// MARK: - UITableViewDataSource
extension SearchViewController: UITableViewDataSource {
  func tableView(
    _ tableView: UITableView,
    numberOfRowsInSection section: Int
  ) -> Int {
    self.viewModel.numberOfRowsInSection()
  }
  
  func tableView(
    _ tableView: UITableView,
    cellForRowAt indexPath: IndexPath
  ) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(
      withIdentifier: RecentSearchKeywordCell.id,
      for: indexPath
    ) as? RecentSearchKeywordCell else { return UITableViewCell() }
    cell.delegate = self
    
    let keyword = viewModel.cellForRow(at: indexPath)
    cell.configure(keyword: keyword)
    
    return cell
  }
}

// MARK: - Actions
private extension SearchViewController {
  @objc func cancelButtonTapped() {
    self.viewModel.didTapCancelButton()
  }
}

extension SearchViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    cell.selectionStyle = .none
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    // 버튼 클릭 시, 해당 키워드의 검색 결과 화면으로 이동
  }
}

// MARK: - RecentSearchKeywordCellDelegate
extension SearchViewController: RecentSearchKeywordCellDelegate {
  func didTapDeleteButton(in cell: UITableViewCell) {
    guard let indexPath = tableView.indexPath(for: cell) else { return }
    
    self.viewModel.didTapKeywordDeleteButton(at: indexPath)
  }
}
