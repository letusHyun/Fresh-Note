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
  
  // MARK: - LifeCycle
  init(viewModel: any AccountDeletionViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }
  
  @MainActor required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - SetupUI
  override func setupLayout() {
    self.view.addSubview(self.alertLabel)
    self.view.addSubview(self.descriptionView)
    
    self.alertLabel.snp.makeConstraints {
      $0.top.equalTo(self.view.safeAreaLayoutGuide).offset(24)
      $0.leading.equalToSuperview().inset(25)
    }
    
    self.descriptionView.snp.makeConstraints {
      $0.top.equalTo(self.alertLabel.snp.bottom).offset(38)
      $0.leading.trailing.equalToSuperview().inset(20)
    }
  }
  
  // MARK: - Bind
}
