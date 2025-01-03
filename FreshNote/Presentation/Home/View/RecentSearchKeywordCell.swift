//
//  RecentSearchKeywordCell.swift
//  FreshNote
//
//  Created by SeokHyun on 11/1/24.
//

import UIKit

protocol RecentSearchKeywordCellDelegate: AnyObject {
  func didTapDeleteButton(in cell: UITableViewCell)
}

final class RecentSearchKeywordCell: UITableViewCell {
  // MARK: - Properties
  static var id: String {
    return String(describing: Self.self)
  }
  
  private let keywordLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.pretendard(size: 12, weight: ._400)
    label.textColor = .black
    return label
  }()
  
  private let deleteButton: UIButton = {
    let button = UIButton()
    button.setImage(UIImage(systemName: "xmark"), for: .normal)
    button.tintColor = .black
    return button
  }()
  
  weak var delegate: RecentSearchKeywordCellDelegate?
  
  // MARK: - LifeCycle
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    self.setupLayout()
    self.setupStyle()
    self.addTargets()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    self.keywordLabel.text = nil
  }
}

// MARK: - Helpers
extension RecentSearchKeywordCell {
  func configure(keyword: ProductQuery) {
    self.keywordLabel.text = keyword.keyword
  }
}

// MARK: - Private Helpers
extension RecentSearchKeywordCell {
  private func addTargets() {
    self.deleteButton.addTarget(self, action: #selector(self.deleteButtonTapped), for: .touchUpInside)
  }
  
  private func setupLayout() {
    self.contentView.addSubview(self.keywordLabel)
    self.contentView.addSubview(self.deleteButton)
    
    self.keywordLabel.translatesAutoresizingMaskIntoConstraints = false
    self.deleteButton.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      self.keywordLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      self.keywordLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      self.keywordLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 13),
      self.keywordLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.deleteButton.leadingAnchor, constant: -30)
    ] + [
      self.deleteButton.widthAnchor.constraint(equalToConstant: 20),
      self.deleteButton.heightAnchor.constraint(equalTo: self.deleteButton.widthAnchor),
      self.deleteButton.centerYAnchor.constraint(equalTo: self.keywordLabel.centerYAnchor),
      self.deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15)
    ])
    
    self.deleteButton.setContentCompressionResistancePriority(.required, for: .horizontal)
  }
  
  private func setupStyle() {
    
  }
}

// MARK: - Actions
private extension RecentSearchKeywordCell {
  @objc func deleteButtonTapped() {
    self.delegate?.didTapDeleteButton(in: self)
  }
}
