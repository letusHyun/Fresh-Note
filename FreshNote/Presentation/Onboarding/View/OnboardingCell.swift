//
//  OnboardingCell.swift
//  FreshNote
//
//  Created by SeokHyun on 10/20/24.
//

import UIKit
import Lottie

final class OnboardingCell: UICollectionViewCell {
  // MARK: - Properties
  static var id: String {
    return String(describing: Self.self)
  }
  
  private let titleLabel: UILabel = {
    let lb = UILabel()
    lb.font = .pretendard(size: 22, weight: ._600)
    lb.textColor = UIColor(fnColor: .gray3)
    lb.textAlignment = .center
    return lb
  }()
  
  private let descriptionLabel: UILabel = {
    let lb = UILabel()
    lb.font = .pretendard(size: 18, weight: ._500)
    lb.textColor = UIColor(fnColor: .gray3)
    lb.textAlignment = .center
    return lb
  }()
  
  private let lottieView: LottieAnimationView = {
    let view = LottieAnimationView(animation: nil)
    view.contentMode = .scaleAspectFit
    view.loopMode = .loop
    return view
  }()
  
  // MARK: - LifeCycle
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - Configure
extension OnboardingCell {
  func configure(with info: OnboardingCellInfo) {
    self.titleLabel.text = info.title
    self.descriptionLabel.text = info.description
    
    self.lottieView.stop()
    self.lottieView.animation = LottieAnimation.named(info.lottieName)
    self.lottieView.play()
  }
}

// MARK: - Private Helpers
private extension OnboardingCell {
  func setupUI() {
    self.setupLayout()
  }
  
  func setupLayout() {
    self.contentView.addSubview(self.lottieView)
    self.contentView.addSubview(self.titleLabel)
    self.contentView.addSubview(self.descriptionLabel)
    
    self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
    self.lottieView.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate(
      [
        self.lottieView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 70),
        self.lottieView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
        self.lottieView.widthAnchor.constraint(equalToConstant: 300),
        self.lottieView.heightAnchor.constraint(equalTo: lottieView.widthAnchor),
      ]
      +
      [
        self.titleLabel.topAnchor.constraint(equalTo: self.lottieView.bottomAnchor, constant: 43),
        self.titleLabel.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor),
      ]
      +
      [
        self.descriptionLabel.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 5),
        self.descriptionLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      ]
    )
  }
}
