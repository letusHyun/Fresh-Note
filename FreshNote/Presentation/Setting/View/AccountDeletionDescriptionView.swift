//
//  AccountDeletionDescriptionView.swift
//  FreshNote
//
//  Created by SeokHyun on 1/23/25.
//

import UIKit

import SnapKit

final class AccountDeletionDescriptionView: UIView {
  // MARK: - Properties
  private lazy var firstLabel: UILabel = {
    let lb = UILabel()
    self.configureFirstLabel(with: lb)
    return lb
  }()
  
  private lazy var secondLabel: UILabel = {
    let lb = UILabel()
    self.configureSecondLabel(with: lb)
    return lb
  }()
  
  private var bulletPoint: String {
    "\u{2022}"
  }
  
  private var verticalPadding: CGFloat { 12 }
  
  private var interPadding: CGFloat { 20 }
 
  override var intrinsicContentSize: CGSize {
    let firstLabelHeight = self.firstLabel.intrinsicContentSize.height
    let secondLabelHeight = self.secondLabel.intrinsicContentSize.height
    
    return CGSize(
      width: UIView.noIntrinsicMetric,
      height: firstLabelHeight + secondLabelHeight + (self.verticalPadding * 2) + self.interPadding
    )
  }
  
  // MARK: - LifeCycle
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.configureFirstLabel(with: self.firstLabel)
    self.configureSecondLabel(with: self.secondLabel)
    self.setupLayout()
    self.setupStyle()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - SetupUI
  private func setupStyle() {
    self.layer.borderColor = UIColor(fnColor: .gray0).cgColor
    self.layer.borderWidth = 1
  }
  
  private func setupLayout() {
    self.addSubview(self.firstLabel)
    self.addSubview(self.secondLabel)
    
    self.firstLabel.snp.makeConstraints {
      $0.top.equalToSuperview().inset(self.verticalPadding)
      $0.leading.trailing.equalToSuperview().inset(20)
    }
    
    self.secondLabel.snp.makeConstraints {
      $0.top.equalTo(self.firstLabel.snp.bottom).offset(self.interPadding)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.bottom.equalToSuperview().inset(self.verticalPadding)
    }
  }
  
  // MARK: - Private
  private func configureFirstLabel(with label: UILabel) {
    let firstParsing = "탈퇴 시 Fresh Note 계정이 삭제되며"
    let secondParsing = "수집된 개인정보(알람, 제품 정보)를"
    let thirdParsing = "복구할 수 없습니다."
    
    let text = [self.bulletPoint, firstParsing, secondParsing, thirdParsing].joined(separator: " ")
    let attributedString = NSMutableAttributedString(string: text)
    
    let grayRange = (text as NSString).range(of: firstParsing)
    self.configureGray(at: attributedString, range: grayRange)
    
    let blackBoldRange = (text as NSString).range(of: secondParsing)
    self.configureBlackBold(at: attributedString, range: blackBoldRange)
    
    let redBoldRange = (text as NSString).range(of: thirdParsing)
    self.configureRedBold(at: attributedString, range: redBoldRange)
    
    label.attributedText = attributedString
    label.numberOfLines = .zero
  }
  
  private func configureSecondLabel(with label: UILabel) {
    let firstParsing = "탈퇴 처리가 되면"
    let secondParsing = "Fresh Note와 연결된 모든 기기의 연동이 해제됩니다."
  
    let text = [self.bulletPoint, firstParsing, secondParsing].joined(separator: " ")
    let attributedString = NSMutableAttributedString(string: text)
    
    let grayRange = (text as NSString).range(of: firstParsing)
    self.configureGray(at: attributedString, range: grayRange)
    
    let blackBoldRange = (text as NSString).range(of: secondParsing)
    self.configureBlackBold(at: attributedString, range: blackBoldRange)
    
    label.attributedText = attributedString
    label.numberOfLines = .zero
  }
  
  private func configureGray(at attributedString: NSMutableAttributedString, range: NSRange) {
    attributedString.addAttributes(
      [
        .foregroundColor: UIColor(fnColor: .gray2),
        .font: UIFont.pretendard(size: 14, weight: ._500)
      ],
      range: range
    )
  }
  
  private func configureBlackBold(at attributedString: NSMutableAttributedString, range: NSRange) {
    attributedString.addAttributes(
      [
        .foregroundColor: UIColor(fnColor: .black),
        .font: UIFont.pretendard(size: 14, weight: ._600)
      ],
      range: range
    )
  }
  
  private func configureRedBold(at attributedString: NSMutableAttributedString, range: NSRange) {
    attributedString.addAttributes(
      [
        .foregroundColor: UIColor(hex: "#FF3B30"),
        .font: UIFont.pretendard(size: 14, weight: ._600)
      ],
      range: range
    )
  }
}
