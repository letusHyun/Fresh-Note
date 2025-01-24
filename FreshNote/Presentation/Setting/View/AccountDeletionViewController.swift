//
//  AccountDeletionViewController.swift
//  FreshNote
//
//  Created by SeokHyun on 1/23/25.
//

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
  
  private lazy var recognizeButton: UIButton = {
    return self.makeRecognizeButton()
  }()
  
  private var subscriptions: Set<AnyCancellable> = []
  
  @Published private var isRecognizeButtonTapped: Bool = false
  
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
    self.setupNavigationBar()
  }
  
  // MARK: - SetupUI
  override func setupLayout() {
    self.view.addSubview(self.alertLabel)
    self.view.addSubview(self.descriptionView)
    self.view.addSubview(self.recognizeButton)
    
    self.alertLabel.snp.makeConstraints {
      $0.top.equalTo(self.view.safeAreaLayoutGuide).offset(24)
      $0.leading.equalToSuperview().inset(25)
    }
    
    self.descriptionView.snp.makeConstraints {
      $0.top.equalTo(self.alertLabel.snp.bottom).offset(38)
      $0.leading.trailing.equalToSuperview().inset(20)
    }
    
    self.recognizeButton.snp.makeConstraints {
      $0.top.equalTo(self.descriptionView.snp.bottom).offset(23.5)
      $0.leading.trailing.equalTo(self.descriptionView)
      $0.height.equalTo(63)
    }
  }
  
  // MARK: - Bind
  private func bindActions() {
    self.recognizeButton
      .tapPublisher
      .sink { [weak self] _ in
        self?.isRecognizeButtonTapped.toggle()
      }
      .store(in: &self.subscriptions)
    
    self.$isRecognizeButtonTapped
      .sink { [weak self] isRecognizeButtonTapped in
        self?.configureRecognizeButtonState(isRecognizeButtonTapped)
      }
      .store(in: &self.subscriptions)
  }
  
  // MARK: - Private
  private func setupNavigationBar() {
    self.title = "탈퇴하기"
  }
  
  private func makeRecognizeButton() -> UIButton {
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
    button.setImage(UIImage(systemName: ImageName.checkmark.rawValue), for: .normal)
    button.layer.cornerRadius = 2
    return button
  }
  
  private func configureRecognizeButtonState(_ isRecognizeButtonTapped: Bool) {
    let imageName: String
    let recognizeButtonColor: UIColor
    if isRecognizeButtonTapped {
      imageName = ImageName.checkmarkTap.rawValue
      recognizeButtonColor = UIColor(fnColor: .orange2).withAlphaComponent(0.2)
    } else {
      imageName = ImageName.checkmark.rawValue
      recognizeButtonColor = UIColor(fnColor: .base)
    }
    
    self.recognizeButton.setImage(
      UIImage(systemName: imageName)?
        .withTintColor(UIColor(fnColor: .orange2), renderingMode: .alwaysOriginal),
      for: .normal
    )
    self.recognizeButton.configuration?.baseBackgroundColor = recognizeButtonColor
  }
}
