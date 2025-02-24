//
//  PhotoBottomSheetViewModel.swift
//  FreshNote
//
//  Created by SeokHyun on 11/23/24.
//
import AVFoundation
import Foundation

struct PhotoBottomSheetViewModelActions {
  let presentPhotoLibrary: () -> Void
  let presentCameraAuthorizationWarning: () -> Void
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
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    
    switch status {
    case .authorized:
      self.actions.presentCamera()
    case .denied, .restricted:
      self.actions.presentCameraAuthorizationWarning()
      // 사메라 사용 불가 alert present
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
        DispatchQueue.main.async {
          if granted {
            self?.actions.presentCamera()
          } else {
            // 사메라 사용 불가 alert present
            self?.actions.presentCameraAuthorizationWarning()
          }
        }
      }
    @unknown default:
      break
    }
  }
  
  func didTapDeleteButton() {
    self.actions.deleteImageAndDisMissBottomSheet()
  }
  
  func didTapPhotoDetailButton() {
    self.actions.presentPhotoDetail()
  }
}
