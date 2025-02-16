//
//  FNAlertViewController.swift
//  FreshNote
//
//  Created by SeokHyun on 2/16/25.
//

import Combine
import UIKit

import SnapKit

class FNAlertViewController: UIViewController {
  // MARK: - Properties
  private let alertView: UIView = {
    let view = UIView()
    view.layer.cornerRadius = 16
    view.backgroundColor = UIColor(fnColor: .realBack)
    return view
  }()
  
  private let titleLabel: UILabel = {
    let lb = UILabel()
    lb.font = UIFont.pretendard(size: 16, weight: ._700)
    lb.textAlignment = .center
    return lb
  }()
  
  private let messageLabel: UILabel = {
    let lb = UILabel()
    lb.font = UIFont.pretendard(size: 15, weight: ._400)
    lb.textAlignment = .center
    lb.numberOfLines = .zero
    return lb
  }()
  
  private let horizontalDividerView: UIView = {
    let view = UIView()
    view.backgroundColor = .lightGray
    return view
  }()
  
  private let confirmButton: UIButton = {
    let button = UIButton()
    button.setTitleColor( .black, for: .normal)
    button.titleLabel?.font = UIFont.pretendard(size: 16, weight: ._600)
    return button
  }()
  
  private var subscriptions: Set<AnyCancellable> = []
  
  private var alertTitle: String?
  private var message: String?
  private var confirmAction: (() -> Void)?
  
  // MARK: - LifeCycle
  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
    self.bindActions()
  }
  
  deinit {
    print("DEBUG: \(Self.self) deinit")
  }
  
  // MARK: - SetupUI
  private func setupUI() {
    self.setupLayout()
    self.setupStyle()
  }
  
  private func setupStyle() {
    self.view.backgroundColor = UIColor.darkGray.withAlphaComponent(0.7)
  }
  
  private func setupLayout() {
    self.view.addSubview(self.alertView)
    self.alertView.addSubview(self.titleLabel)
    self.alertView.addSubview(self.messageLabel)
    self.alertView.addSubview(self.horizontalDividerView)
    self.alertView.addSubview(self.confirmButton)
    
    self.alertView.snp.makeConstraints {
      $0.width.equalTo(300)
      $0.center.equalToSuperview()
    }
    
    self.titleLabel.snp.makeConstraints {
      $0.width.equalTo(260)
      $0.centerX.equalToSuperview()
      $0.top.equalToSuperview().offset(30)
    }
    
    self.messageLabel.snp.makeConstraints {
      $0.width.equalTo(260)
      $0.centerX.equalToSuperview()
      $0.top.equalTo(self.titleLabel.snp.bottom).offset(20)
    }
    
    self.horizontalDividerView.snp.makeConstraints {
      $0.width.centerX.equalToSuperview()
      $0.height.equalTo(0.5)
      $0.top.equalTo(self.messageLabel.snp.bottom).offset(30)
    }
    
    self.confirmButton.snp.makeConstraints {
      $0.width.equalTo(300)
      $0.centerX.equalToSuperview()
      $0.height.equalTo(50)
      $0.top.equalTo(self.horizontalDividerView.snp.bottom)
      $0.bottom.equalToSuperview()
    }
  }
  
  // MARK: - Bind
  private func bindActions() {
    self.confirmButton
      .tapThrottlePublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.confirmAction?()
        self?.dismiss(animated: true)
      }
      .store(in: &self.subscriptions)
  }
  
  // MARK: - Helpers
  func setTitle(_ text: String) {
    self.titleLabel.text = text
  }
  
  func setMessage(_ text: String) {
    self.messageLabel.text = text
  }
  
  func setActionConfirm(_ alertAction: FNAlertAction) {
    self.confirmButton.setTitle(alertAction.text, for: .normal)
    self.confirmAction = alertAction.action
  }
}

