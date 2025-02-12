//
//  PlaceholderTextView.swift
//  FreshNote
//
//  Created by SeokHyun on 11/15/24.
//

import Combine
import UIKit

import SnapKit

final class PlaceholderTextView: UITextView {
  // MARK: - Constants
//  var leftPadding: CGFloat { 25 }
//  
//  var topPadding: CGFloat { 8 }
  
  // MARK: - Properties
  private lazy var placeholderLabel: UILabel = {
    let label = UILabel()
    label.textColor = UIColor(fnColor: .gray1)
    label.font = self.font
    return label
  }()
  
  var placeholder: String? {
    didSet {
      self.placeholderLabel.text = self.placeholder
      self.updatePlaceholderVisibility()
    }
  }
  
  private var subscriptions = Set<AnyCancellable>()
  
  /// 외부에서 delegate를 사용하도록 정의하고 내부에서는 externalDelegate로 바꿔서 사용
  /// PlaceholderTextView에서 UITextViewDelegate 메소드를 구현할 때, externalDelegate를 호출시켜주어야 합니다.
  private weak var externalDelegate: (any UITextViewDelegate)?
  
  override var delegate: (any UITextViewDelegate)? {
    get {
      super.delegate
    }
    set {
      self.externalDelegate = newValue
      super.delegate = self
    }
  }
  
  private let keyboardToolbar = BaseKeyboardToolbar()
  
  var doneTapPublisher: AnyPublisher<Void, Never> {
    self.keyboardToolbar.tapPublisher.eraseToAnyPublisher()
  }
  
  // MARK: - LifeCycle
  /// 해당 init을 통해 inset을 지정해야합니다.
  convenience init(textContainerInset: UIEdgeInsets) {
    self.init(frame: .zero, textContainer: nil)
    self.setupLayout(with: textContainerInset)
    self.addObserver()
    self.setupStyle(with: textContainerInset)
    self.bind()
    self.setupToolbar()
  }
  
  override init(frame: CGRect, textContainer: NSTextContainer?) {
    super.init(frame: frame, textContainer: textContainer)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Private Helpers
  private func setupToolbar() {
    self.inputAccessoryView = self.keyboardToolbar
  }
  
  private func bind() {
    self.keyboardToolbar.tapPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.endEditing(true)
      }
      .store(in: &self.subscriptions)
  }
  
  private func addObserver() {
    NotificationCenter.default
      .publisher(for: UITextView.textDidChangeNotification, object: self)
      .sink { [weak self] _ in
        self?.self.updatePlaceholderVisibility()
      }
      .store(in: &self.subscriptions)
  }
  
  private func setupLayout(with textContainerInset: UIEdgeInsets) {
    self.addSubview(self.placeholderLabel)
    
    self.placeholderLabel.snp.makeConstraints {
      $0.top.equalToSuperview().inset(textContainerInset.top)
      $0.leading.equalToSuperview().inset(textContainerInset.left + 4)
    }
  }
  
  func updatePlaceholderVisibility() {
    self.placeholderLabel.isHidden = !text.isEmpty
  }
  
  private func setupStyle(with textContainerInset: UIEdgeInsets) {
    self.textContainerInset = textContainerInset
    self.textColor = .black
  }
}

// MARK: - UITextViewDelegate
extension PlaceholderTextView: UITextViewDelegate {
  func textViewDidBeginEditing(_ textView: UITextView) {
    self.updatePlaceholderVisibility()
    
    self.externalDelegate?.textViewDidBeginEditing?(textView)
  }
}
