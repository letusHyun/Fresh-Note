//
//  SettingHeaderView.swift
//  FreshNote
//
//  Created by SeokHyun on 1/17/25.
//

import Foundation
import UIKit

import SnapKit

final class SettingHeaderView: UITableViewHeaderFooterView {
  // MARK: - Properties
  static var id: String {
    return String(describing: Self.self)
  }
  
  private let titleLabel: UILabel = {
    let lb = UILabel()
    lb.font = UIFont.pretendard(size: 18, weight: ._600)
    lb.textColor = .black
    return lb
  }()
  
  // MARK: - LifeCycle
  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    self.setupStyle()
    self.setupLayout()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - SetupUI
  private func setupStyle() {
    self.contentView.backgroundColor = UIColor(fnColor: .realBack)
  }
  
  private func setupLayout() {
    self.contentView.addSubview(self.titleLabel)
    
    self.titleLabel.snp.makeConstraints {
      $0.centerY.equalToSuperview()
      $0.leading.equalTo(25)
    }
  }
  
  // MARK: - Configure
  func configure(with text: String) {
    self.titleLabel.text = text
  }
}
