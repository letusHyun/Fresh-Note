//
//  BaseViewController.swift
//  FreshNote
//
//  Created by SeokHyun on 10/19/24.
//

import UIKit

class BaseViewController: UIViewController {
  // MARK: - LifeCycle
  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
    self.setupNavigationinteractivePopGestureRecognizer()
  }
  
  // MARK: - UI
  func setupUI() {
    self.setupStyle()
    self.setupLayout()
  }
  
  func setupStyle() {
    self.view.backgroundColor = UIColor(fnColor: .realBack)
  }
  
  func setupLayout() { }
  
  // MARK: - Private
  private func setupNavigationinteractivePopGestureRecognizer() {
    self.navigationController?.interactivePopGestureRecognizer?.delegate = self
  }
}

// MARK: - UIGestureRecognizerDelegate
extension BaseViewController: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    return self.navigationController?.viewControllers.count ?? 0 > 1
  }
}
