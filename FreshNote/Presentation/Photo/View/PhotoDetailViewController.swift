//
//  PhotoDetailViewController.swift
//  FreshNote
//
//  Created by SeokHyun on 2/13/25.
//

import Combine
import UIKit

import SnapKit

final class PhotoDetailViewController: BaseViewController {
  // MARK: - Properties
  private let viewModel: any PhotoDetailViewModel
  
  private let imageView: UIImageView = {
    let iv = UIImageView()
    iv.clipsToBounds = true
    iv.contentMode = .scaleAspectFill
    return iv
  }()
  
  private var subscriptions: Set<AnyCancellable> = []
  
  // MARK: - LifeCycle
  init(viewModel: any PhotoDetailViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }
  
  @MainActor required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    defer { self.viewModel.viewDidLoad() }
    
    self.bind(to: self.viewModel)
  }
  
  // MARK: - SetupUI
  override func setupStyle() {
    self.view.backgroundColor = .black
  }
  
  // MARK: - Bind
  private func bind(to viewModel: any PhotoDetailViewModel) {
    viewModel
      .imageDataPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] imageData in
        guard let self else { return }
        
        self.imageView.image = UIImage(data: imageData)
        self.setupImageViewLayout()
      }
      .store(in: &self.subscriptions)
  }
  
  // MARK: - Private
  private func setupImageViewLayout() {
    guard let imageSize = self.imageView.image?.size else { return }
    
    self.view.addSubview(self.imageView)
    
    if imageSize.width >= imageSize.height { // 가로 사진
      self.imageView.snp.makeConstraints {
        $0.leading.trailing.equalToSuperview()
        $0.centerY.equalToSuperview()
        $0.height.equalTo(self.imageView.snp.width).multipliedBy(imageSize.height / imageSize.width)
      }
    } else {
      self.imageView.snp.makeConstraints {
        $0.top.bottom.equalToSuperview()
        $0.centerX.equalToSuperview()
        $0.width.equalTo(self.imageView.snp.height).multipliedBy(imageSize.width / imageSize.height)
      }
    }
  }
}
