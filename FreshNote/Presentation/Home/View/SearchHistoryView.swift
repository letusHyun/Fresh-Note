//
//  SearchHistoryView.swift
//  FreshNote
//
//  Created by SeokHyun on 1/8/25.
//

import Combine
import UIKit

import SnapKit

protocol SearchHistoryViewDelegate: AnyObject {
  func didSelectRow()
}

final class SearchHistoryView: UIView {
  // MARK: - Properties
  private let activityIndicatorView = ActivityIndicatorView()
  
  private let recentSearchTagLabel: UILabel = {
    let lb = UILabel()
    lb.font = UIFont.pretendard(size: 15, weight: ._700)
    lb.text = "최근 검색"
    lb.textColor = UIColor(fnColor: .gray2)
    return lb
  }()
  
  private let allDeletionButton: UIButton = {
    let button: UIButton = UIButton()
    button.setTitle("전체 삭제", for: .normal)
    button.titleLabel?.font = UIFont.pretendard(size: 15, weight: ._600)
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
    tv.separatorStyle = .none
    return tv
  }()
  
  private let viewModel: any SearchHistoryViewModel
  
  private var subscriptions: Set<AnyCancellable> = []
  
  weak var delegate: (any SearchHistoryViewDelegate)?
  
  // MARK: - LifeCycle
  init(viewModel: any SearchHistoryViewModel) {
    self.viewModel = viewModel
    super.init(frame: .zero)
    
    self.setupUI()
    self.bind(to: viewModel)
    self.bindActions()
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
    self.addSubview(self.recentSearchTagLabel)
    self.addSubview(self.allDeletionButton)
    self.addSubview(self.tableView)
    self.addSubview(self.activityIndicatorView)
    
    self.recentSearchTagLabel.snp.makeConstraints {
      $0.top.equalToSuperview().inset(20)
      $0.leading.equalToSuperview().inset(15)
    }
    
    self.allDeletionButton.snp.makeConstraints {
      $0.centerY.equalTo(self.recentSearchTagLabel)
      $0.trailing.equalToSuperview().inset(10)
    }
    
    self.tableView.snp.makeConstraints {
      $0.top.equalTo(allDeletionButton.snp.bottom).offset(2)
      $0.leading.trailing.bottom.equalToSuperview()
    }
    
    self.activityIndicatorView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
  }
  
  // MARK: - Bind
  private func bind(to viewModel: any SearchHistoryViewModel) {
    viewModel.historyErrorPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] error in
        guard let error = error else { return }
        self?.activityIndicatorView.stopIndicating()
      }
      .store(in: &self.subscriptions)
    
    viewModel.historyReloadDataPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in
        self?.activityIndicatorView.stopIndicating()
        self?.tableView.reloadData()
      }
      .store(in: &self.subscriptions)
    
    viewModel.historyDeleteRowsPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] indexPath in
        self?.activityIndicatorView.stopIndicating()
        self?.tableView.deleteRows(at: [indexPath], with: .fade)
      }
      .store(in: &self.subscriptions)
  }
  
  private func bindActions() {
    self.allDeletionButton
      .tapThrottlePublisher
      .sink { [weak self] in
        self?.activityIndicatorView.startIndicating()
        self?.viewModel.didTapAllDeletionButton()
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
    self.viewModel.historyNumberOfRowsInSection()
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
    self.delegate?.didSelectRow()
    self.viewModel.historyDidSelectRow(at: indexPath)
  }
}

// MARK: - RecentSearchKeywordCellDelegate
extension SearchHistoryView: RecentSearchKeywordCellDelegate {
  func didTapDeleteButton(in cell: UITableViewCell) {
    guard let indexPath = tableView.indexPath(for: cell) else { return }
    
    self.activityIndicatorView.startIndicating()
    self.viewModel.didTapKeywordDeleteButton(at: indexPath)
  }
}
