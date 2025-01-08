//
//  SearchHistoryView.swift
//  FreshNote
//
//  Created by SeokHyun on 1/8/25.
//

import Combine
import UIKit

import SnapKit

final class SearchHistoryView: UIView {
  typealias SearchHistoryViewModel = SearchHistoryViewModelInput
  & SearchHistoryViewModelOutput
  & SearchViewModelInput
  & SearchViewModelOutput
  
  // MARK: - Properties
  private let recentSearchTagLabel: UILabel = {
    let lb = UILabel()
    lb.font = UIFont.pretendard(size: 12, weight: ._400)
    lb.text = "최근 검색어"
    lb.textColor = UIColor(fnColor: .gray2)
    return lb
  }()
  
  private let allDeletionButton: UIButton = {
    let button: UIButton = UIButton()
    button.setTitle("전체 삭제", for: .normal)
    button.setTitleColor(.black, for: .normal)
    return button
  }()
  
  private lazy var tableView: UITableView = {
    let tv = UITableView()
    tv.dataSource = self
    tv.delegate = self
    tv.rowHeight = 60
    tv.register(
      RecentSearchKeywordCell.self,
      forCellReuseIdentifier: RecentSearchKeywordCell.id
    )
    return tv
  }()
  
  private let viewModel: any SearchHistoryViewModel
  
  private let viewModelType: SearchViewModelType
  
  private var subscriptions: Set<AnyCancellable> = []
  
  // MARK: - LifeCycle
  init(viewModel: any SearchHistoryViewModel) {
    self.viewModel = viewModel
    self.viewModelType = SearchViewModelType.history
    super.init(frame: .zero)
    
    self.bind(to: viewModel)
    self.setupUI()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - SetupUI
  private func setupUI() {
    self.setupLayout()
    self.setupStyles()
  }
  
  private func setupStyles() {
    
  }
  
  private func setupLayout() {
    self.addSubview(self.tableView)
    
    self.tableView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
  }
  
  // MARK: - Bind
  private func bind(to viewModel: any SearchHistoryViewModel) {
    viewModel.historyErrorPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] error in
        guard let error = error else { return }
        ActivityIndicatorView.shared.stopIndicating()
      }
      .store(in: &self.subscriptions)
    
    viewModel.historyReloadDataPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in
        ActivityIndicatorView.shared.stopIndicating()
        self?.tableView.reloadData()
      }
      .store(in: &self.subscriptions)
    
    viewModel.historyDeleteRowsPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] indexPath in
        ActivityIndicatorView.shared.stopIndicating()
        self?.tableView.deleteRows(at: [indexPath], with: .fade)
      }
      .store(in: &self.subscriptions)
  }
}

// MARK: - UITableViewDataSource
extension SearchHistoryView: UITableViewDataSource {
  func tableView(
    _ tableView: UITableView,
    numberOfRowsInSection section: Int
  ) -> Int {
    self.viewModel.numberOfRowsInSection(viewModelType: self.viewModelType)
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

// MARK: - UITableViewDelegate
extension SearchHistoryView: UITableViewDelegate {
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    cell.selectionStyle = .none
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    self.viewModel.didSelectRow(at: indexPath, viewModelType: self.viewModelType)
  }
}

// MARK: - RecentSearchKeywordCellDelegate
extension SearchHistoryView: RecentSearchKeywordCellDelegate {
  func didTapDeleteButton(in cell: UITableViewCell) {
    guard let indexPath = tableView.indexPath(for: cell) else { return }
    
    ActivityIndicatorView.shared.startIndicating()
    self.viewModel.didTapKeywordDeleteButton(at: indexPath)
  }
}
