//
//  SignOutAlertViewController.swift
//  FreshNote
//
//  Created by SeokHyun on 1/19/25.
//

import Combine
import UIKit

import SnapKit

final class SignOutAlertViewController: UIViewController {
  // MARK: - Properties
  enum Constants {
    static var cornerRadius: CGFloat { 14 }
  }
  
  private var subscriptions: Set<AnyCancellable> = []
  
  private let containerView: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    view.layer.cornerRadius = Constants.cornerRadius
    return view
  }()
  
  private let titleLabel: UILabel = {
    let lb = UILabel()
    lb.font = UIFont.pretendard(size: 18, weight: ._600)
    lb.textColor = UIColor(fnColor: .gray3)
    lb.text = "로그아웃"
    return lb
  }()
  
  private let descriptionLabel: UILabel = {
    let lb = UILabel()
    lb.text = "로그아웃 하시겠습니까?"
    lb.font = UIFont.pretendard(size: 18, weight: ._500)
    lb.textColor = UIColor(fnColor: .gray1)
    return lb
  }()
  
  private let buttonStackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .horizontal
    stackView.distribution = .fillEqually
    stackView.alignment = .fill
    stackView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    stackView.layer.cornerRadius = Constants.cornerRadius
    stackView.clipsToBounds = true
    return stackView
  }()
  
  private let cancelButton: UIButton = {
    let btn = UIButton()
    btn.setTitle("취소", for: .normal)
    btn.setTitleColor(UIColor(fnColor: .gray3), for: .normal)
    btn.titleLabel?.font = UIFont.pretendard(size: 18, weight: ._400)
    btn.backgroundColor = UIColor(hex: "#F9F9F9")
    return btn
  }()
  
  private let signOutButton: UIButton = {
    let btn = UIButton()
    btn.setTitle("로그아웃", for: .normal)
    btn.setTitleColor(UIColor(hex: "#FF3B30"), for: .normal)
    btn.titleLabel?.font = UIFont.pretendard(size: 18, weight: ._400)
    btn.backgroundColor = UIColor(hex: "#F9F9F9")
    return btn
  }()
  
  private let viewModel: any SignOutAlertViewModel
  
  // MARK: - Lifecycle
  init(viewModel: any SignOutAlertViewModel) {
    self.viewModel = viewModel
    
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
    self.bindActions()
  }
  
  // MARK: - Setup
  private func setupUI() {
    view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    
    view.addSubview(self.containerView)
    [self.titleLabel, self.descriptionLabel, self.buttonStackView]
      .forEach { self.containerView.addSubview($0) }
    [self.cancelButton, self.signOutButton]
      .forEach { self.buttonStackView.addArrangedSubview($0) }
    
    self.setupConstraints()
  }
  
  private func setupConstraints() {
    self.containerView.snp.makeConstraints {
      $0.center.equalToSuperview()
      $0.width.equalTo(270)
    }
    
    self.titleLabel.snp.makeConstraints {
      $0.top.equalToSuperview().inset(48)
      $0.centerX.equalToSuperview()
    }
    
    self.descriptionLabel.snp.makeConstraints {
      $0.top.equalTo(self.titleLabel.snp.bottom).offset(27)
      $0.centerX.equalToSuperview()
    }
    
    self.buttonStackView.snp.makeConstraints {
      $0.top.equalTo(self.descriptionLabel.snp.bottom).offset(62)
      $0.leading.trailing.equalToSuperview()
      $0.height.equalTo(70)
      $0.bottom.equalToSuperview()
    }
  }
  
  // MARK: - Bind
  private func bindActions() {
    self.cancelButton
      .tapPublisher
      .sink { [weak self] _ in
        self?.viewModel.didTapCancelButton()
      }
      .store(in: &self.subscriptions)
    
    self.signOutButton
      .tapThrottlePublisher
      .sink { [weak self] _ in
        self?.viewModel.didTapSignOutButton()
      }
      .store(in: &self.subscriptions)
  }
}
