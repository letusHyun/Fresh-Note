//
//  DynamicTextField.swift
//  FreshNote
//
//  Created by SeokHyun on 11/15/24.
//

import Combine
import UIKit

final class DynamicTextField: UITextField {
  // MARK: - Properties
  private let dashLayer = CAShapeLayer()
  
  private var subscriptions = Set<AnyCancellable>()
  
  private var widthConstraint: NSLayoutConstraint?
  
  private var borderHeight: CGFloat { 1 }
  
  private let widthConstant: CGFloat
  
  /// textField의 width가 변경되었을 때만 dashLayer의 width를 설정하도록 하는 변수입니다.
  private var previousWidth: CGFloat = 0
  
  private let bezierPath = UIBezierPath()
  
  private let pencilImageView: UIImageView = {
    let iv = UIImageView(image: UIImage(named: "pencil"))
    iv.contentMode = .scaleAspectFit
    return iv
  }()
  
  private let keyboardToolbar = BaseKeyboardToolbar()
  
  // MARK: - LifeCycle
  init(borderColor: UIColor, widthConstant: CGFloat) {
    self.widthConstant = widthConstant
    
    super.init(frame: .zero)
    
    self.setupLayout()
    self.setupStyle(borderColor: borderColor)
    self.bind()
    self.setupToolbar()
    self.delegate = self
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    let shouldUpdateDashedBorder = self.previousWidth != self.bounds.width
    
    if shouldUpdateDashedBorder {
      self.previousWidth = self.bounds.width
      self.updateDashedBorder()
    }
  }
  
  // MARK: - SetupUI
  private func setupLayout() {
    self.layer.addSublayer(self.dashLayer)
    self.addSubview(self.pencilImageView)
    
    self.translatesAutoresizingMaskIntoConstraints = false
    self.pencilImageView.translatesAutoresizingMaskIntoConstraints = false
    
    self.widthConstraint = self.widthAnchor.constraint(equalToConstant: self.widthConstant)
    self.widthConstraint?.isActive = true
    
    NSLayoutConstraint.activate([
      self.pencilImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 1.5),
      self.pencilImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -2),
      self.pencilImageView.widthAnchor.constraint(equalToConstant: 15),
      self.pencilImageView.heightAnchor.constraint(equalToConstant: 15)
    ])
  }
  
  private func setupStyle(borderColor: UIColor) {
    self.dashLayer.strokeColor = borderColor.cgColor
    self.dashLayer.frame.size.height = 1
    self.dashLayer.strokeColor = UIColor.black.cgColor
    self.dashLayer.lineWidth = 1
    self.dashLayer.fillColor = nil
    self.dashLayer.lineDashPattern = [2, 2]
  }
  
  // MARK: - Private Helpers
  private func setupToolbar() {
    self.inputAccessoryView = self.keyboardToolbar
  }
  
  private func bind() {
    self.textEditingChangedPublisher
      .compactMap { [weak self] text in
        guard let self = self else { return nil }
        
        let textWidth = text.size(withAttributes: [.font: self.font!]).width
        return max(100, textWidth + 40)
      }
      .sink { [weak self] newWidth in
        self?.updateLayout(with: newWidth)
      }
      .store(in: &self.subscriptions)
    
    self.keyboardToolbar
      .tapPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in
        self?.endEditing(true)
      }
      .store(in: &self.subscriptions)
  }
  
  private func updateLayout(with newWidth: CGFloat) {
    self.widthConstraint?.constant = newWidth
  }
  
  private func updateDashedBorder() {
    self.bezierPath.removeAllPoints()
    
    let destinationHeight = self.bounds.height - self.borderHeight + 4
    self.bezierPath.move(to: CGPoint(x: .zero, y: destinationHeight))
    self.bezierPath.addLine(to: CGPoint(x: self.bounds.width, y: destinationHeight))
    
    self.dashLayer.path = self.bezierPath.cgPath
  }
}

// MARK: - UITextFieldDelegate
extension DynamicTextField: UITextFieldDelegate {
  func textFieldDidBeginEditing(_ textField: UITextField) {
    self.pencilImageView.isHidden = true
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    self.pencilImageView.isHidden = !(textField.text?.isEmpty ?? true)
  }
}
