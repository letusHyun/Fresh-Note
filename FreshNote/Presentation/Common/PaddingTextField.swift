//
//  PaddingTextField.swift
//  FreshNote
//
//  Created by SeokHyun on 11/1/24.
//

import Combine
import UIKit

import SnapKit

/// 텍스트 left padding을 제공해주는 객체입니다.
class PaddingTextField: UITextField {
  // MARK: - Properties
  private let keyboardToolbar = BaseKeyboardToolbar()
  
  private var subscriptions = Set<AnyCancellable>()
  
  /// 키보드 완료 버튼 tap 방출 Publisher입니다.
  var doneTapPublisher: AnyPublisher<Void, Never> {
    self.keyboardToolbar.tapPublisher.eraseToAnyPublisher()
  }
  
  // MARK: - LifeCycle
  init(leftPadding: CGFloat = 25, clearButtonMode: UITextField.ViewMode = .always) {
    super.init(frame: .zero)
    self.setPadding(leftPadding: leftPadding)
    self.setupToolbar()
    self.bind()
    self.clearButtonMode = clearButtonMode
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Bind
  private func bind() {
    self.keyboardToolbar.tapPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in
        self?.endEditing(true)
      }
      .store(in: &self.subscriptions)
  }

  // MARK: - Private
  private func setupToolbar() {
    self.inputAccessoryView = self.keyboardToolbar
  }
  
  private func setPadding(leftPadding: CGFloat) {
    self.leftView  = UIView(frame: CGRect(x: .zero, y: .zero, width: leftPadding, height: frame.height))
    self.leftViewMode = .always
  }
}
