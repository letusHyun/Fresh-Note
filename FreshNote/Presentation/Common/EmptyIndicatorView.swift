//
//  EmptyIndicatorView.swift
//  FreshNote
//
//  Created by SeokHyun on 2/11/25.
//

import UIKit

import SnapKit

/// cell의 데이터가 존재하지 않을 때 보여주는 View입니다.
final class EmptyIndicatorView: UIView {
  // MARK: - Properties
  private let imageView = UIImageView()
  
  private let titleLabel: UILabel = {
    let lb = UILabel()
    lb.font = UIFont.pretendard(size: 18, weight: ._600)
    lb.textColor = UIColor(fnColor: .gray3)
    return lb
  }()
  
  private let descriptionLabel: UILabel = {
    let lb = UILabel()
    lb.font = UIFont.pretendard(size: 14, weight: ._400)
    lb.textColor = UIColor(fnColor: .gray2)
    return lb
  }()
  
  private let stackView: UIStackView = {
    let sv = UIStackView()
    sv.axis = .vertical
    sv.spacing = 20
    sv.distribution = .fill
    sv.alignment = .center
    return sv
  }()
  
  // MARK: - LifeCycle
  init(title: String, description: String, imageName: ImageName) {
    super.init(frame: .zero)
    self.setupUI()
    self.configure(title: title, description: description, imageName: imageName)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - SetupUI
  private func setupUI() {
    self.setupLayout()
  }
  
  private func setupLayout() {
    self.addSubview(self.stackView)
    [
      self.imageView,
      self.titleLabel,
      self.descriptionLabel
    ].forEach {
      self.stackView.addArrangedSubview($0)
    }
    
    self.stackView.snp.makeConstraints {
      $0.center.equalToSuperview()
    }
    
    self.imageView.snp.makeConstraints {
      $0.size.equalTo(50)
    }
  }
  
  // MARK: - Private
  private func configure(title: String, description: String, imageName: ImageName) {
    self.titleLabel.text = title
    self.descriptionLabel.text = description
    switch imageName {
    case .custom(let name):
      self.imageView.image = UIImage(named: name)?
        .withTintColor(UIColor(fnColor: .gray0), renderingMode: .alwaysOriginal)
    case .system(let name):
      self.imageView.image = UIImage(systemName: name)?
        .withTintColor(UIColor(fnColor: .gray0), renderingMode: .alwaysOriginal)
    case .noImage:
      self.stackView.removeArrangedSubview(self.imageView)
      return
    }
  }
  
  // MARK: - Helpers
  /// collectionView 혹은 tableView를 통해 visibility를 update할 때 사용합니다.
  func updateVisibility(shouldHidden: Bool, from view: UIView) {
    let newBackground: UIView? = shouldHidden ? nil : self
    
    switch view {
    case let tableView as UITableView:
      tableView.backgroundView = newBackground
    case let collectionView as UICollectionView:
      collectionView.backgroundView = newBackground
    default:
      return
    }
  }
}
