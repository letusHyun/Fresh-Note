//
//  SettingCell.swift
//  FreshNote
//
//  Created by SeokHyun on 1/17/25.
//

import Foundation
import UIKit

import SnapKit

final class SettingCell: UITableViewCell {
  // MARK: - Properties
  static var id: String {
    String(describing: Self.self)
  }
  
  private let titleLabel: UILabel = {
    let lb = UILabel()
    lb.font = UIFont.pretendard(size: 16, weight: ._400)
    lb.textColor = .black
    return lb
  }()
  
  // MARK: - LifeCycle
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    self.setupLayout()
    self.setupStyle()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    self.titleLabel.text = nil
  }
  
  // MARK: - SetupUI
  private func setupStyle() {
    self.contentView.backgroundColor = UIColor(fnColor: .realBack)
  }
  
  private func setupLayout() {
    self.contentView.addSubview(titleLabel)
    
    self.titleLabel.snp.makeConstraints {
      $0.centerY.equalToSuperview()
      $0.leading.equalToSuperview().inset(25)
    }
  }
  
  // MARK: - Configure
  func configure(with title: String) {
    self.titleLabel.text = title
  }
}
