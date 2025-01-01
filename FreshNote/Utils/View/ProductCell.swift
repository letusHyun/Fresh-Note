//
//  ProductCell.swift
//  FreshNote
//
//  Created by SeokHyun on 10/30/24.
//

import Combine
import UIKit

import SnapKit

final class ProductCell: UITableViewCell {
  // MARK: - Properteis
  static var id: String {
    return String(describing: Self.self)
  }
  
  private let thumbnailImageView: UIImageView = {
    let iv = UIImageView()
    iv.contentMode = .scaleAspectFill
    iv.layer.cornerRadius = 7
    iv.clipsToBounds = true
    iv.layer.borderWidth = 2
    iv.layer.borderColor = UIColor(fnColor: .orange1).cgColor
    return iv
  }()
  
  private let nameLabel: UILabel = {
    let label = UILabel()
    return label
  }()
  
  private let expirationDateLabel: UILabel = {
    let lb = UILabel()
    return lb
  }()
  
  private let categoryLabel: UILabel = {
    let lb = UILabel()
    return lb
  }()
  
  private let memoLabel: UILabel = {
    let lb = UILabel()
    return lb
  }()
  
  private var subscriptions = Set<AnyCancellable>()
  
  private let pinImageView: UIImageView = {
    let iv = UIImageView()
    return iv
  }()
  
  private let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy.MM.dd"
    return dateFormatter
  }()
  
  // MARK: - LifeCycle
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    self.setupLayout()
    self.setupLabelsStyle(labels: [self.nameLabel, self.expirationDateLabel, self.categoryLabel, self.memoLabel])
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    self.thumbnailImageView.image = nil
    self.nameLabel.text = nil
    self.categoryLabel.text = nil
    self.expirationDateLabel.text = nil
    self.memoLabel.text = nil
    self.pinImageView.image = nil
  }
}

// MARK: - Helpers
extension ProductCell {
  func configure(product: Product) {
    self.configureProductImage(with: product.imageURL)
    self.configurePin(isPinned: product.isPinned)
    self.expirationDateLabel.text = self.dateFormatter.string(from: product.expirationDate)
    self.nameLabel.text = product.name
    self.categoryLabel.text = product.category
    self.memoLabel.text = product.memo
  }
}

// MARK: - Private Helpers
extension ProductCell {
  private func configurePin(isPinned: Bool) {
    let imageName = isPinned ? "v.circle.fill" : "v.circle"
    self.pinImageView.image = UIImage(systemName: imageName)
  }
  
  private func configureProductImage(with imageURL: URL?) {
    if let imageURL = imageURL {
      URLSession.shared.dataTaskPublisher(for: imageURL)
        .map { UIImage(data: $0.data) }
        .replaceError(with: nil)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] image in
          self?.thumbnailImageView.image = image
        }
        .store(in: &self.subscriptions)
      
    } else {
      self.thumbnailImageView.image = UIImage(named: "defaultProductImage")?
        .withInsets(UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5))
    }
  }
  
  private func setupLayout() {
    self.thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
    
    let textContainerView: UIView = {
      let view = UIView()
      view.translatesAutoresizingMaskIntoConstraints = false
      view.layer.cornerRadius = 3
      view.layer.borderWidth = 1.5
      view.layer.borderColor = UIColor(fnColor: .orange1).cgColor
      return view
    }()
    
    let tagLabels = makeAndSetupStyleTagLabels()
    let mainLabels = [self.nameLabel, self.expirationDateLabel, self.categoryLabel, self.memoLabel].map {
      $0.translatesAutoresizingMaskIntoConstraints = false
      return $0
    }
    _=(tagLabels + mainLabels)
      .map { textContainerView.addSubview($0) }
    contentView.addSubview(thumbnailImageView)
    contentView.addSubview(textContainerView)
    
    let nameTagLabel = tagLabels[0]
    let expirationTagLabel = tagLabels[1]
    let categoryTagLabel = tagLabels[2]
    let memoTagLabel = tagLabels[3]
    
    // container
    NSLayoutConstraint.activate([
      nameTagLabel.topAnchor.constraint(equalTo: textContainerView.topAnchor, constant: 5),
      nameTagLabel.leadingAnchor.constraint(equalTo: textContainerView.leadingAnchor, constant: 5),
      nameLabel.centerYAnchor.constraint(equalTo: nameTagLabel.centerYAnchor),
      nameLabel.leadingAnchor.constraint(equalTo: nameTagLabel.trailingAnchor),
      nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: textContainerView.trailingAnchor, constant: -5)
    ]+[
      expirationTagLabel.topAnchor.constraint(equalTo: nameTagLabel.bottomAnchor, constant: 4),
      expirationTagLabel.leadingAnchor.constraint(equalTo: textContainerView.leadingAnchor, constant: 5),
      expirationDateLabel.centerYAnchor.constraint(equalTo: expirationTagLabel.centerYAnchor),
      expirationDateLabel.leadingAnchor.constraint(equalTo: expirationTagLabel.trailingAnchor),
      expirationDateLabel.trailingAnchor.constraint(lessThanOrEqualTo: textContainerView.trailingAnchor, constant: -5)
    ]+[
      categoryTagLabel.topAnchor.constraint(equalTo: expirationTagLabel.bottomAnchor, constant: 4),
      categoryTagLabel.leadingAnchor.constraint(equalTo: textContainerView.leadingAnchor, constant: 5),
      categoryLabel.centerYAnchor.constraint(equalTo: categoryTagLabel.centerYAnchor),
      categoryLabel.leadingAnchor.constraint(equalTo: categoryTagLabel.trailingAnchor),
      categoryLabel.trailingAnchor.constraint(lessThanOrEqualTo: textContainerView.trailingAnchor, constant: -5)
    ]+[
      memoTagLabel.topAnchor.constraint(equalTo: categoryTagLabel.bottomAnchor, constant: 4),
      memoTagLabel.leadingAnchor.constraint(equalTo: textContainerView.leadingAnchor, constant: 5),
      memoTagLabel.bottomAnchor.constraint(equalTo: textContainerView.bottomAnchor, constant: -5),
      memoLabel.centerYAnchor.constraint(equalTo: memoTagLabel.centerYAnchor),
      memoLabel.leadingAnchor.constraint(equalTo: memoTagLabel.trailingAnchor),
      memoLabel.trailingAnchor.constraint(lessThanOrEqualTo: textContainerView.trailingAnchor, constant: -5)
    ])
    
    // outer
    NSLayoutConstraint.activate([
      thumbnailImageView.topAnchor.constraint(equalTo: textContainerView.topAnchor, constant: 5),
      thumbnailImageView.bottomAnchor.constraint(equalTo: textContainerView.bottomAnchor, constant: -5),
      thumbnailImageView.widthAnchor.constraint(equalToConstant: 80),
      thumbnailImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10)
    ]+[
      textContainerView.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 10),
      textContainerView.topAnchor.constraint(equalTo: contentView.topAnchor,constant: 5),
      textContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
      textContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5)
    ])
  }
  
  private func setupLabelsStyle(labels: [UILabel]) {
    _=labels.map {
      $0.font = UIFont.pretendard(size: 14, weight: ._400)
      $0.textColor = .black
    }
  }

  private func makeAndSetupStyleTagLabels() -> [UILabel] {
    let labels = ["상품명: ", "유통기한: ", "카테고리: ", "메모: "].map {
      let label = UILabel()
      label.text = $0
      label.translatesAutoresizingMaskIntoConstraints = false
      label.setContentCompressionResistancePriority(.required, for: .horizontal)
      return label
    }
    setupLabelsStyle(labels: labels)
    return labels
  }
}
