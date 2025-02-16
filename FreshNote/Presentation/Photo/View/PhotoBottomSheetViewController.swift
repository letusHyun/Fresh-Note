//
//  PhotoBottomSheetViewController.swift
//  FreshNote
//
//  Created by SeokHyun on 11/22/24.
//

import Combine
import UIKit

import SnapKit

final class PhotoBottomSheetViewController: UIViewController {
  // MARK: - Properties
  private let viewModel: any PhotoBottomSheetViewModel
  
  private let albumButton: PhotoBottomSheetButton = {
    let button = PhotoBottomSheetButton(
      title: "앨범에서 사진 선택",
      image: UIImage(systemName: "photo"),
      color: .black
    )
    
    return button
  }()
  
  private let cameraButton: PhotoBottomSheetButton = {
    let button = PhotoBottomSheetButton(
      title: "사진 찍기",
      image: UIImage(systemName: "camera"),
      color: .black
    )
    return button
  }()
  
  private let deleteButton: PhotoBottomSheetButton = {
    let button = PhotoBottomSheetButton(
      title: "사진 삭제",
      image: UIImage(systemName: "trash"),
      color: UIColor(fnColor: .red)
    )
    return button
  }()
  
  private lazy var photoDetailButton: PhotoBottomSheetButton = {
    let button = PhotoBottomSheetButton(
      title: "사진 전체 보기",
      image: UIImage(systemName: "rectangle.center.inset.filled"),
      color: .black
    )
    return button
  }()
  
  private var subscriptions = Set<AnyCancellable>()
  private let shouldConfigurePhotoDetailButton: Bool
  
  // MARK: - LifeCycle
  init(viewModel: any PhotoBottomSheetViewModel, shouldConfigurePhotoDetailButton: Bool) {
    self.viewModel = viewModel
    self.shouldConfigurePhotoDetailButton = shouldConfigurePhotoDetailButton
    
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupLayout()
    self.bind()
  }
  
  deinit {
    print("DEBUG: \(Self.self) deinit")
  }
  
  // MARK: - Private Helpers
  func bind() {
    self.albumButton.gesture()
      .sink { [weak self] _ in
        self?.viewModel.didTapAlbumButton()
      }
      .store(in: &self.subscriptions)
    
    self.cameraButton.gesture()
      .sink { [weak self] _ in
        self?.viewModel.didTapCameraButton()
      }
      .store(in: &self.subscriptions)
    
    self.deleteButton.gesture()
      .sink { [weak self] _ in
        self?.viewModel.didTapDeleteButton()
      }
      .store(in: &self.subscriptions)
    
    self.photoDetailButton.gesture()
      .sink { [weak self] _ in
        self?.viewModel.didTapPhotoDetailButton()
      }
      .store(in: &self.subscriptions)
  }
  
  
  private func setupLayout() {
    var arrangedSubviews: [UIView] = [
      self.albumButton,
      self.cameraButton,
      self.deleteButton
    ]
    
    // default image 여부에 따라서 사진 전체보기 버튼 보이기/안보이기
    if self.shouldConfigurePhotoDetailButton {
      arrangedSubviews.insert(self.photoDetailButton, at: .zero)
    }
    
    let stackView: UIStackView = {
      let sv = UIStackView()
      sv.axis = .vertical
      sv.distribution = .fillEqually
      sv.alignment = .fill
      return sv
    }()
    
    arrangedSubviews.forEach { stackView.addArrangedSubview($0) }
    
    let buttonHeight: CGFloat = 48
    
    self.albumButton.snp.makeConstraints {
      $0.height.equalTo(buttonHeight)
    }
    
    self.view.addSubview(stackView)
    
    stackView.snp.makeConstraints {
      $0.top.equalToSuperview().inset(20)
      $0.leading.trailing.equalToSuperview().inset(16.5)
      $0.bottom.equalToSuperview().inset(14)
      $0.height.equalTo(buttonHeight * 3)
    }
  }
}
