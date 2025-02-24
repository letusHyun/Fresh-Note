//
//  FreshNoteTitleView.swift
//  FreshNote
//
//  Created by SeokHyun on 10/23/24.
//

import UIKit

final class FreshNoteTitleView: UIView {
  enum Constants {
    static let underlineHeight: CGFloat = 0.5
  }
  
  // MARK: - Properties
  private let titleLabel: UILabel = {
    let label = UILabel()
    let text = "Fresh Note"
    label.text = text
    label.textColor = UIColor(fnColor: .gray3)
    label.font = UIFont(name: "AvenirLTStd-Book", size: 30)
    
    return label
  }()
  
  private let underlineView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor(fnColor: .gray3)
    return view
  }()
  
  override var intrinsicContentSize: CGSize {
    let labelHeight = titleLabel.intrinsicContentSize.height
    let width = titleLabel.intrinsicContentSize.width
    let height = labelHeight + Constants.underlineHeight
    
    return CGSize(width: width, height: height)
  }
  
  // MARK: - LifeCycle
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - Private Helpers
extension FreshNoteTitleView {
  private func setupUI() {
    setupStyle()
    setupLayout()
  }
  
  private func setupStyle() {
    
  }
  
  private func setupLayout() {
    addSubview(titleLabel)
    addSubview(underlineView)
    
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    underlineView.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
      titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
      titleLabel.topAnchor.constraint(equalTo: topAnchor),
      
      underlineView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
      underlineView.leadingAnchor.constraint(equalTo: leadingAnchor),
      underlineView.trailingAnchor.constraint(equalTo: trailingAnchor),
      underlineView.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])
  }
}

