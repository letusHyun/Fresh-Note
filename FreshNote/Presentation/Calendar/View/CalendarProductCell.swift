//
//  CalendarProductCell.swift
//  FreshNote
//
//  Created by SeokHyun on 12/25/24.
//

import Foundation
import UIKit

import SnapKit

final class CalendarProductCell: UICollectionViewCell {
  static var id: String {
    String(describing: Self.self)
  }
  
  private let titleLabel: UILabel = {
    let lb = UILabel()
    lb.font = UIFont.pretendard(size: 10, weight: ._400)
    lb.textColor = .black
    return lb
  }()
  
  private let titleTagLabel: UILabel = {
    let lb = UILabel()
    lb.text = "상품명: "
    lb.font = UIFont.pretendard(size: 10, weight: ._400)
    lb.textColor = .black
    return lb
  }()
  
  private let expirationLabel: UILabel = {
    let lb = UILabel()
    lb.font = UIFont.pretendard(size: 10, weight: ._400)
    lb.textColor = .black
    return lb
  }()
  
  private let expirationTagLabel: UILabel = {
    let lb = UILabel()
    lb.text = "유통기한: "
    lb.font = UIFont.pretendard(size: 10, weight: ._400)
    lb.textColor = .black
    return lb
  }()
  
  private let categoryLabel: UILabel = {
    let lb = UILabel()
    lb.font = UIFont.pretendard(size: 10, weight: ._400)
    lb.textColor = .black
    return lb
  }()
  
  private let categoryTagLabel: UILabel = {
    let lb = UILabel()
    lb.text = "카테고리: "
    lb.font = UIFont.pretendard(size: 10, weight: ._400)
    lb.textColor = .black
    return lb
  }()
  
  private let formatterManager: DateFormatManager = DateFormatManager()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.setupLayouts()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setupLayouts() {
    self.contentView.addSubview(self.titleTagLabel)
    self.contentView.addSubview(self.titleLabel)
    self.contentView.addSubview(self.expirationTagLabel)
    self.contentView.addSubview(self.expirationLabel)
    self.contentView.addSubview(self.categoryTagLabel)
    self.contentView.addSubview(self.categoryLabel)
    
    // TODO: - 오토레이아웃 정의하기
    
    
  }
  
  func configure(with product: Product) {
    self.titleLabel.text = product.name
    self.categoryLabel.text = product.category
    let expiration = self.formatterManager.string(from: product.expirationDate)
    self.expirationLabel.text = expiration
  }
}
