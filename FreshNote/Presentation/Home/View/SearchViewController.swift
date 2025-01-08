//
//  SearchViewController.swift
//  FreshNote
//
//  Created by SeokHyun on 11/1/24.
//

import Combine
import UIKit

import SnapKit

final class SearchViewController: BaseViewController {
  // MARK: - Properties
  private lazy var textField: PaddingTextField = {
    let tf = PaddingTextField()
    tf.layer.borderColor = UIColor(fnColor: .orange2).cgColor
    tf.layer.borderWidth = 0.8
    tf.layer.cornerRadius = 3
    let placeholderAttr = NSAttributedString(
      string: "상품명을 검색해주세요.",
      attributes: [
        NSAttributedString.Key.font: UIFont.pretendard(size: 12, weight: ._400),
        NSAttributedString.Key.foregroundColor: UIColor(fnColor: .gray1)
      ]
    )
    tf.returnKeyType = .search
    tf.attributedPlaceholder = placeholderAttr
    tf.delegate = self
    return tf
  }()
  
  private let backButton: UIButton = {
    let btn = UIButton()
    btn.setTitle("닫기", for: .normal)
    btn.titleLabel?.font = UIFont.pretendard(size: 15, weight: ._400)
    btn.setTitleColor(UIColor(fnColor: .gray2), for: .normal)
    return btn
  }()
  
  private lazy var searchHistoryView: SearchHistoryView = {
    return SearchHistoryView(viewModel: self.viewModel)
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
    defer {
      ActivityIndicatorView.shared.startIndicating()
      self.viewModel.viewDidLoad()
    }
    
    self.bindActions()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.navigationController?.setNavigationBarHidden(true, animated: true)
    self.tabBarController?.tabBar.isHidden = true
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.navigationController?.setNavigationBarHidden(false, animated: true)
    self.tabBarController?.tabBar.isHidden = false
  }
  
  // MARK: - SetupUI
  override func setupLayout() {
    self.view.addSubview(self.textField)
    self.view.addSubview(self.backButton)
    self.view.addSubview(self.searchHistoryView)
    
    self.textField.snp.makeConstraints {
      $0.top.equalTo(self.view.safeAreaLayoutGuide).inset(15)
      $0.leading.equalToSuperview().inset(10)
      $0.height.equalTo(40)
    }
    
    self.backButton.snp.makeConstraints {
      $0.leading.equalTo(self.textField.snp.trailing).offset(10)
      $0.trailing.equalToSuperview().inset(10)
      $0.centerY.equalTo(self.textField.snp.centerY)
      $0.width.equalTo(33)
      $0.height.equalTo(self.textField.snp.height)
    }
    
    self.searchHistoryView.snp.makeConstraints {
      $0.top.equalTo(self.textField.snp.bottom).offset(5)
      $0.leading.trailing.equalToSuperview()
      $0.bottom.equalToSuperview()
    }
  }
  
  // MARK: - Bind
  private func bindActions() {
    self.backButton.tapPublisher
      .sink { [weak self] _ in
        self?.viewModel.didTapCancelButton()
      }
      .store(in: &self.subscriptions)
  }
  
  // MARK: - Private
}

// MARK: - UITextFieldDelegate
extension SearchViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    guard let text = textField.text, text != "" else { return false }
    
    self.viewModel.textFieldShouldReturn(keyword: text)
    textField.resignFirstResponder()
    
    return true
  }
}
