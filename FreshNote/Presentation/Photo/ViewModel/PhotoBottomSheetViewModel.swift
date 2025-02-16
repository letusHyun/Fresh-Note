//
//  PhotoBottomSheetViewModel.swift
//  FreshNote
//
//  Created by SeokHyun on 11/23/24.
//

import Foundation

struct PhotoBottomSheetViewModelActions {
  let presentPhotoLibrary: () -> Void
  let presentCamera: () -> Void
  let presentPhotoDetail: () -> Void
  let deleteImageAndDisMissBottomSheet: () -> Void
}

typealias PhotoBottomSheetViewModel = PhotoBottomSheetViewModelInput & PhotoBottomSheetViewModelOutput

protocol PhotoBottomSheetViewModelInput {
  func didTapPhotoDetailButton()
  func didTapAlbumButton()
  func didTapCameraButton()
  func didTapDeleteButton()
}

protocol PhotoBottomSheetViewModelOutput {
  
}

final class DefaultPhotoBottomSheetViewModel: PhotoBottomSheetViewModel {
  // MARK: - Properties
  private let actions: PhotoBottomSheetViewModelActions
  
  // MARK: - Output
  
  // MARK: - LifeCycle
  init(actions: PhotoBottomSheetViewModelActions) {
    self.actions = actions
  }
  
  // MARK: - Input
  func didTapAlbumButton() {
    self.actions.presentPhotoLibrary()
  }
  
  func didTapCameraButton() {
    self.actions.presentCamera()
  }
  
  func didTapDeleteButton() {
    self.actions.deleteImageAndDisMissBottomSheet()
  }
  
  func didTapPhotoDetailButton() {
    self.actions.presentPhotoDetail()
  }
}
