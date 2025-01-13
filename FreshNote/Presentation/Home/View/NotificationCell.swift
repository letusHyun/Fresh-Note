//
//  NotificationCell.swift
//  FreshNote
//
//  Created by SeokHyun on 10/31/24.
//

import UIKit

final class NotificationCell: UITableViewCell {
  // MARK: - Properties
  static var id: String {
    return String(describing: Self.self)
  }
  
  private let descriptionLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.pretendard(size: 18, weight: ._400)
    label.textColor = .black
    return label
  }()
  
  // MARK: - LifeCycle
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupLayout()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    descriptionLabel.text = nil
    contentView.backgroundColor = nil
  }
}

// MARK: - Private Helpers
extension NotificationCell {
  private func setupLayout() {
    contentView.addSubview(descriptionLabel)
    
    descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      descriptionLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      descriptionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
      descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 25),
      descriptionLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -10)
    ])
  }
}

// MARK: - Helpers
extension NotificationCell {
  func configure(notification: ProductNotification) {
    descriptionLabel.text = "\(notification.productName)의 유통기한이 D-\(notification.dDay) 남았습니다."
    
    if !notification.isViewed {
      contentView.backgroundColor = UIColor(hex: "#FFA03A", alpha: 0.3)
    } else {
      contentView.backgroundColor = .white
    }
  }
}
