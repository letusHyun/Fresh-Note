//
//  BaseKeyboardToolbar.swift
//  FreshNote
//
//  Created by SeokHyun on 11/19/24.
//

import Combine
import UIKit

final class BaseKeyboardToolbar: UIToolbar {
  // MARK: - Properties
  /// 키보드 완료 버튼 tap 방출 Publisher입니다.
  var tapPublisher: AnyPublisher<Void, Never> { self.tapSubject.eraseToAnyPublisher() }
  
  private let tapSubject: PassthroughSubject<Void, Never> = .init()
  
  private let doneButton: UIButton = {
    let btn = UIButton()
    btn.setTitle("완료", for: .normal)
    btn.setTitleColor(UIColor(fnColor: .gray3), for: .normal)
    return btn
  }()

  private var subscriptions = Set<AnyCancellable>()
  
  // MARK: - LifeCycle
  init() {
    super.init(frame: CGRect(
      x: .zero,
      y: .zero,
      width: UIScreen.main.bounds.width,
      height: 50
    ))
    self.setupToolbar()
    self.bind()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Private Helpers
  private func bind() {
    self.doneButton.tapPublisher
      .sink { [weak self] _ in
        self?.tapSubject.send()
      }
      .store(in: &self.subscriptions)
  }
  
  private func setupToolbar() {
    let emptySpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    let barButtonItem = UIBarButtonItem(customView: self.doneButton)
    self.items = [emptySpace, barButtonItem]
  }
}
