//
//  AccountDeletionViewController.swift
//  FreshNote
//
//  Created by SeokHyun on 1/23/25.
//

import AuthenticationServices
import Combine
import UIKit

import SnapKit

final class AccountDeletionViewController: BaseViewController {
  enum ImageName: String {
    case checkmark = "checkmark.circle"
    case checkmarkTap = "checkmark.circle.fill"
  }
  
  // MARK: - Properties
  private let viewModel: any AccountDeletionViewModel
  
  private let alertLabel: UILabel = {
    let lb = UILabel()
    lb.text = "탈퇴하기 전에 꼭 확인해주세요.😢"
    lb.font = UIFont.pretendard(size: 16, weight: ._600)
    lb.textColor = UIColor(fnColor: .black)
    return lb
  }()
  
  private let descriptionView = AccountDeletionDescriptionView()
  
  private lazy var agreeButton: UIButton = {
    return self.makeAgreeButton()
  }()
  
  private lazy var deleteAccountButton: UIButton = {
    return self.makeDeleteAccountButton()
  }()
  
  private var subscriptions: Set<AnyCancellable> = []
  
  @Published private var isAgreeButtonTapped: Bool = false
  
  private let activityIndicatorView = ActivityIndicatorView()
  
  // MARK: - LifeCycle
  init(viewModel: any AccountDeletionViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }
  
  @MainActor required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.bindActions()
    self.bind()
    self.setupNavigationBar()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.tabBarController?.tabBar.isHidden = true
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.tabBarController?.tabBar.isHidden = false
  }
  
  // MARK: - SetupUI
  override func setupLayout() {
    defer {
      self.view.addSubview(self.activityIndicatorView)
      self.activityIndicatorView.snp.makeConstraints {
        $0.top.bottom.equalTo(self.view.safeAreaLayoutGuide)
        $0.leading.trailing.equalToSuperview()
      }
    }
    
    self.view.addSubview(self.alertLabel)
    self.view.addSubview(self.descriptionView)
    self.view.addSubview(self.agreeButton)
    self.view.addSubview(self.deleteAccountButton)
    
    self.alertLabel.snp.makeConstraints {
      $0.top.equalTo(self.view.safeAreaLayoutGuide).offset(24)
      $0.leading.equalToSuperview().inset(25)
    }
    
    self.descriptionView.snp.makeConstraints {
      $0.top.equalTo(self.alertLabel.snp.bottom).offset(38)
      $0.leading.trailing.equalToSuperview().inset(20)
    }
    
    self.agreeButton.snp.makeConstraints {
      $0.top.equalTo(self.descriptionView.snp.bottom).offset(23.5)
      $0.leading.trailing.equalTo(self.descriptionView)
      $0.height.equalTo(63)
    }
    
    self.deleteAccountButton.snp.makeConstraints {
      $0.leading.trailing.equalToSuperview()
      $0.height.equalTo(89)
      $0.bottom.equalToSuperview()
    }
  }
  
  // MARK: - Bind
  private func bind() {
    self.viewModel.activityIndicatePublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] shouldIndicate in
        shouldIndicate ?
        self?.activityIndicatorView.startIndicating() :
        self?.activityIndicatorView.stopIndicating()
      }
      .store(in: &self.subscriptions)
  }
  
  private func bindActions() {
    self.agreeButton
      .tapPublisher
      .sink { [weak self] _ in
        self?.isAgreeButtonTapped.toggle()
      }
      .store(in: &self.subscriptions)
    
    self.$isAgreeButtonTapped
      .dropFirst()
      .sink { [weak self] isAgreeButtonTapped in
        self?.configureAgreeButtonState(isAgreeButtonTapped)
        self?.configureDeleteAccountButtonState(isAgreeButtonTapped)
      }
      .store(in: &self.subscriptions)
    
    self.deleteAccountButton
      .tapPublisher
      .sink { [weak self] _ in
        guard let self else { return }
        
        let authController = self.viewModel.makeASAuthorizationController()
        authController.presentationContextProvider = self
        self.viewModel.didTapDeleteAccountButton(authController: authController)
      }
      .store(in: &self.subscriptions)
  }
  
  // MARK: - Private
  private func setupNavigationBar() {
    self.title = "탈퇴하기"
  }
  
  private func makeAgreeButton() -> UIButton {
    var config = UIButton.Configuration.filled()
    config.attributedTitle = AttributedString(
      "Fresh Note 계정을 탈퇴합니다.",
      attributes: AttributeContainer([
        .font: UIFont.pretendard(size: 16, weight: ._600),
        .foregroundColor: UIColor(fnColor: .gray3)
      ])
    )
    config.imagePadding = 14
    config.contentInsets = NSDirectionalEdgeInsets(top: 22, leading: 16, bottom: 22, trailing: 16)
    config.baseBackgroundColor = UIColor(fnColor: .base)
    
    let button = UIButton(configuration: config)
    let image = UIImage(systemName: ImageName.checkmark.rawValue)?
      .withTintColor(UIColor(fnColor: .gray0), renderingMode: .alwaysOriginal)
    button.setImage(image, for: .normal)
    button.layer.cornerRadius = 2
    return button
  }
  
  private func configureAgreeButtonState(_ isAgreeButtonTapped: Bool) {
    let image: UIImage?
    let AgreeButtonColor: UIColor
    if isAgreeButtonTapped {
      image = UIImage(systemName: ImageName.checkmarkTap.rawValue)?
        .withTintColor(UIColor(fnColor: .orange2), renderingMode: .alwaysOriginal)
      AgreeButtonColor = UIColor(fnColor: .orange2).withAlphaComponent(0.2)
      
      
    } else {
      image = UIImage(systemName: ImageName.checkmark.rawValue)?
        .withTintColor(UIColor(fnColor: .gray0), renderingMode: .alwaysOriginal)
      AgreeButtonColor = UIColor(fnColor: .base)
    }
    
    self.agreeButton.setImage(image, for: .normal)
    self.agreeButton.configuration?.baseBackgroundColor = AgreeButtonColor
  }
  
  private func configureDeleteAccountButtonState(_ isAgreeButtonTapped: Bool) {
    if isAgreeButtonTapped {
      self.deleteAccountButton.isEnabled = true
      self.deleteAccountButton.configuration?.baseBackgroundColor = UIColor(fnColor: .orange2)
      self.deleteAccountButton.configuration?.baseForegroundColor = UIColor(fnColor: .realBack)
    } else {
      self.deleteAccountButton.isEnabled = false
      self.deleteAccountButton.configuration?.baseBackgroundColor = UIColor(fnColor: .blank)
      self.deleteAccountButton.configuration?.baseForegroundColor = UIColor(hex: "#929090")
    }
  }
  
  private func makeDeleteAccountButton() -> UIButton {
    var config = UIButton.Configuration.filled()
    config.attributedTitle = AttributedString(
      "계정 탈퇴",
      attributes: AttributeContainer([
        .font: UIFont.pretendard(size: 16, weight: ._600),
      ])
    )
    config.baseForegroundColor = UIColor(hex: "#929090")
    config.baseBackgroundColor = UIColor(fnColor: .blank)
    let button = UIButton(configuration: config)
    button.layer.cornerRadius = 20
    button.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    button.clipsToBounds = true
    return button
  }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AccountDeletionViewController: ASAuthorizationControllerPresentationContextProviding {
  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    guard let window = self.view.window else {
      return ASPresentationAnchor()
    }
    return window
  }
}
