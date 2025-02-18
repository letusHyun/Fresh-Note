//
//  ActivityIndicatorView.swift
//  FreshNote
//
//  Created by SeokHyun on 12/24/24.
//

import Foundation
import UIKit

import SnapKit

final class ActivityIndicatorView: UIView {
  private let activityIndicator = UIActivityIndicatorView(style: .large)
  
  init() {
    super.init(frame: .zero)
    self.setupUI()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setupUI() {
    self.setupLayouts()
    self.setupStyles()
  }
  
  private func setupLayouts() {
    self.addSubview(self.activityIndicator)
    
    self.activityIndicator.snp.makeConstraints {
      $0.centerX.equalToSuperview()
      $0.centerY.equalToSuperview()
    }
  }
  
  private func setupStyles() {
    self.isHidden = true
    self.backgroundColor = .clear
  }
  
  // MARK: - Public
  func startIndicating() {
    self.activityIndicator.startAnimating()
    self.isHidden = false
  }
  
  func stopIndicating() {
    self.activityIndicator.stopAnimating()
    self.isHidden = true
  }
}
