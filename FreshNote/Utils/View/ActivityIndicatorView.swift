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
  static let shared = ActivityIndicatorView()
  
  private let activityIndicator = UIActivityIndicatorView(style: .large)
  
  private init() {
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
    guard
      let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
      let window = windowScene.windows.first else { return }
    
    window.addSubview(self)
    self.addSubview(self.activityIndicator)
    
    self.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
    
    self.activityIndicator.snp.makeConstraints {
      $0.centerX.equalToSuperview()
      $0.centerY.equalToSuperview()
    }
  }
  
  private func setupStyles() {
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
