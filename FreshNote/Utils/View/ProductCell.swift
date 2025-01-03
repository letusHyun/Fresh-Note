//
//  ProductCell.swift
//  FreshNote
//
//  Created by SeokHyun on 10/30/24.
//

import Combine
import UIKit

import SnapKit

protocol ProductCellDelegate: AnyObject {
  func didTapPin(in cell: UITableViewCell)
}

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
    iv.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 4)
    iv.isUserInteractionEnabled = true
    return iv
  }()
  
  private let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy.MM.dd"
    return dateFormatter
  }()
  
  weak var delegate: (any ProductCellDelegate)?
  
  // MARK: - LifeCycle
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    self.setupLayout()
    self.setupLabelsStyle(labels: [self.nameLabel, self.expirationDateLabel, self.categoryLabel, self.memoLabel])
    self.bind()
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
  
  func configurePin(isPinned: Bool) {
    let imageName = isPinned ? "pin.fill" : "pin"
    self.pinImageView.image = UIImage(systemName: imageName)?
      .withTintColor(.black, renderingMode: .alwaysOriginal)
  }
}

// MARK: - Private Helpers
extension ProductCell {
  private func bind() {
    self.pinImageView.gesture()
      .sink { [weak self] _ in
        guard let self else { return }
        self.delegate?.didTapPin(in: self)
      }
      .store(in: &self.subscriptions)
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
  
  private func makeTextContainerView() -> UIView {
    let view = UIView()
    view.layer.cornerRadius = 3
    view.layer.borderWidth = 1.5
    view.layer.borderColor = UIColor(fnColor: .orange1).cgColor
    return view
  }
  
  private func setupLabelsStyle(labels: [UILabel]) {
    _=labels.map {
      $0.font = UIFont.pretendard(size: 14, weight: ._400)
      $0.textColor = .black
    }
  }

  private func makeAndSetupStyleTagLabels(texts: [String]) -> [UILabel] {
    let labels = texts.map {
      let label = UILabel()
      label.text = $0
      label.setContentCompressionResistancePriority(.required, for: .horizontal)
      return label
    }
    self.setupLabelsStyle(labels: labels)
    return labels
  }
  
  // MARK: - SetupUI
  private func setupLayout() {
    let textContainerView = self.makeTextContainerView()
    let tagLabels = self.makeAndSetupStyleTagLabels(texts: ["상품명: ", "유통기한: ", "카테고리: ", "메모: "])
    let mainLabels = [self.nameLabel, self.expirationDateLabel, self.categoryLabel, self.memoLabel].map {
      return $0
    }
    _=(tagLabels + mainLabels)
      .map { textContainerView.addSubview($0) }
    textContainerView.addSubview(self.pinImageView)
    self.contentView.addSubview(self.thumbnailImageView)
    self.contentView.addSubview(textContainerView)
    
    let nameTagLabel = tagLabels[0]
    let expirationTagLabel = tagLabels[1]
    let categoryTagLabel = tagLabels[2]
    let memoTagLabel = tagLabels[3]
    
    // container
    self.pinImageView.snp.makeConstraints {
      $0.size.equalTo(30)
      $0.top.equalToSuperview().inset(5)
      $0.trailing.equalToSuperview().inset(5)
    }
    
    nameTagLabel.snp.makeConstraints {
      $0.top.equalToSuperview().inset(5)
      $0.leading.equalToSuperview().inset(5)
    }
    self.nameLabel.snp.makeConstraints {
      $0.centerY.equalTo(nameTagLabel)
      $0.leading.equalTo(nameTagLabel.snp.trailing)
      $0.trailing.lessThanOrEqualTo(self.pinImageView.snp.leading).offset(-5)
    }
    
    expirationTagLabel.snp.makeConstraints {
      $0.top.equalTo(nameTagLabel.snp.bottom).offset(4)
      $0.leading.equalToSuperview().inset(5)
    }
    self.expirationDateLabel.snp.makeConstraints {
      $0.centerY.equalTo(expirationTagLabel)
      $0.leading.equalTo(expirationTagLabel.snp.trailing)
      $0.trailing.lessThanOrEqualTo(self.pinImageView.snp.leading).offset(-5)
    }
    
    categoryTagLabel.snp.makeConstraints {
      $0.top.equalTo(expirationTagLabel.snp.bottom).offset(4)
      $0.leading.equalToSuperview().inset(5)
    }
    self.categoryLabel.snp.makeConstraints {
      $0.centerY.equalTo(categoryTagLabel)
      $0.leading.equalTo(categoryTagLabel.snp.trailing)
      $0.trailing.lessThanOrEqualToSuperview().inset(5)
    }
    
    memoTagLabel.snp.makeConstraints {
      $0.top.equalTo(categoryTagLabel.snp.bottom).offset(4)
      $0.leading.equalToSuperview().inset(5)
      $0.bottom.equalToSuperview().inset(5)
    }
    self.memoLabel.snp.makeConstraints {
      $0.centerY.equalTo(memoTagLabel)
      $0.leading.equalTo(memoTagLabel.snp.trailing)
      $0.trailing.lessThanOrEqualToSuperview().inset(5)
    }
    
    // outer
    self.thumbnailImageView.snp.makeConstraints {
      $0.top.equalTo(textContainerView).offset(5)
      $0.bottom.equalTo(textContainerView).offset(-5)
      $0.width.equalTo(80)
      $0.centerY.equalToSuperview()
      $0.leading.equalToSuperview().inset(10)
    }
    textContainerView.snp.makeConstraints {
      $0.leading.equalTo(self.thumbnailImageView.snp.trailing).offset(10)
      $0.top.equalToSuperview().inset(5)
      $0.trailing.equalToSuperview().inset(10)
      $0.bottom.equalToSuperview().inset(5)
    }
  }
}
