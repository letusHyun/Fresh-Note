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
    tf.layer.borderWidth = 1.5
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
    let view = SearchHistoryView(viewModel: self.viewModel)
    view.delegate = self
    return view
  }()
  
  private lazy var resultView: SearchResultView = {
    let view = SearchResultView(viewModel: self.viewModel)
    view.isHidden = true
    return view
  }()
  
  private let viewModel: any SearchViewModel
  
  private var subscriptions: Set<AnyCancellable> = []
  
  private var isFirstViewDidAppear = false
  
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
    self.bindActions()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.navigationController?.setNavigationBarHidden(true, animated: true)
    self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    self.tabBarController?.tabBar.isHidden = true
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if self.isFirstViewDidAppear {
      self.isFirstViewDidAppear.toggle()
      self.textField.becomeFirstResponder()
    }
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
    self.view.addSubview(self.resultView)
    
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
    
    self.resultView.snp.makeConstraints {
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
    
    self.textField
      .publisher(for: .editingDidBegin)
      .sink { [weak self] _ in
        guard let self else { return }
        
        if self.searchHistoryView.isHidden {
          self.appearHistoryView()
        }
      }
      .store(in: &self.subscriptions)
  }
  
  private func bind(to viewModel: any SearchViewModel) {
    viewModel
      .updateTextPubilsher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] text in
        self?.textField.text = text
      }
      .store(in: &self.subscriptions)
  }
  
  // MARK: - Private
  private func appearHistoryView() {
    self.searchHistoryView.isHidden = false
    self.resultView.isHidden = true
  }
  
  private func appearResultView() {
    self.searchHistoryView.isHidden = true
    self.resultView.isHidden = false
  }
}

// MARK: - UITextFieldDelegate
extension SearchViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    guard let text = textField.text, text != "" else { return false }

    self.appearResultView()
    self.viewModel.textFieldShouldReturn(keyword: text)
    textField.resignFirstResponder()
    
    return true
  }
}

// MARK: - SearchHistoryViewDelegate
extension SearchViewController: SearchHistoryViewDelegate {
  func didSelectRow() {
    self.textField.resignFirstResponder()
    self.appearResultView()
  }
}
