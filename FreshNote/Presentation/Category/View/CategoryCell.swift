//
//  CategoryCell.swift
//  FreshNote
//
//  Created by SeokHyun on 11/23/24.
//

import UIKit

final class CategoryCell: UITableViewCell {
  // MARK: - Properties
  static var id: String { return String(describing: Self.self) }
  
  let titleLabel: UILabel = {
    let lb = UILabel()
    lb.font = UIFont.pretendard(size: 17, weight: ._400)
    lb.textColor = .black
    return lb
  }()
  
  
  // MARK: - LifeCycle
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    self.setupLayout()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - SetupUI
  private func setupLayout() {
    contentView.addSubview(self.titleLabel)
    
    self.titleLabel.snp.makeConstraints {
      $0.leading.equalToSuperview().inset(10)
      $0.centerY.equalToSuperview()
    }
  }
  
  // MARK: - Configure
  func configure(text: String) {
    self.titleLabel.text = text
  }
}
