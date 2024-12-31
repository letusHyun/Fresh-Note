//
//  ProductCoordinator.swift
//  FreshNote
//
//  Created by SeokHyun on 11/14/24.
//

import UIKit

//protocol ProductCoordinatorFinishDelegate: AnyObject {
//  func finish(_ childCoordinator: BaseCoordinator, with product: Product?)
//}

protocol ProductCoordinatorDependencies: AnyObject {
  func makeProductViewController(
    actions: ProductViewModelActions,
    mode: ProductViewModelMode
  ) -> ProductViewController
  
  func makeBottomSheetViewController(
    detent: BottomSheetViewController.Detent
  ) -> BottomSheetViewController
  func makePhotoBottomSheetViewController(actions: PhotoBottomSheetViewModelActions) -> UIViewController
  func makeCategoryBottomSheetViewController(actions: CategoryBottomSheetViewModelActions) -> UIViewController
}

final class ProductCoordinator: BaseCoordinator {
  // MARK: - Properties
  private let dependencies: any ProductCoordinatorDependencies
  
  private let mode: ProductViewModelMode
  
  private var photoBottomSheetViewController: UIViewController?
  
  private var categoryBottomSheetViewController: UIViewController?
  
  private var bottomSheetViewController: BottomSheetViewController?
  
//  weak var productCoordinatorFinishDelegate: (any ProductCoordinatorFinishDelegate)?
  
  // MARK: - LifeCycle
  init(
    dependencies: any ProductCoordinatorDependencies,
    navigationController: UINavigationController?,
    mode: ProductViewModelMode
  ) {
    self.dependencies = dependencies
    self.mode = mode
    
    super.init(navigationController: navigationController)
  }
  
  deinit {
    print("DEBUG: \(Self.self) deinit")
  }
  
  // MARK: - Start
  func start() {
    let actions = ProductViewModelActions(
      pop: { [weak self] in
        self?.pop()
      }, showPhotoBottomSheet: { [weak self] passDataHandler in
        self?.showPhotoBottomSheet(passDataHandler: passDataHandler)
      }, showCategoryBottomSheet: { [weak self] (animateCategoryHandler, passCategoryHandler) in
        self?.showCategoryBottomSheet(
          animateCategoryHandler: animateCategoryHandler,
          passCategoryHandler: passCategoryHandler
        )
      }
    )
    
    let viewController = self.dependencies.makeProductViewController(actions: actions, mode: mode)
    self.navigationController?.pushViewController(viewController, animated: true)
  }
}

// MARK: - Private Helpers
extension ProductCoordinator {
  private func pop() {
    self.navigationController?.popViewController(animated: true)
    self.finish()
  }
  
  private func showPhotoBottomSheet(passDataHandler: @escaping (Data?) -> Void) {
    let bottomSheetViewController = self.dependencies.makeBottomSheetViewController(detent: .small)
    bottomSheetViewController.dismissHandler = { [weak self] in
      self?.dismissPhotoBottomSheet()
    }
    self.bottomSheetViewController = bottomSheetViewController
    
    let actions = PhotoBottomSheetViewModelActions(passData: { [weak self] data in
      passDataHandler(data)
      self?.bottomSheetViewController?.hideBottomSheetAndDismiss()
    })
    
    let photoBottomSheetViewController = self.dependencies.makePhotoBottomSheetViewController(actions: actions)
    self.photoBottomSheetViewController = photoBottomSheetViewController
    
    bottomSheetViewController.add(
      child: photoBottomSheetViewController,
      container: bottomSheetViewController.bottomSheetView
    )
    
    bottomSheetViewController.modalPresentationStyle = .overFullScreen
    self.navigationController?.topViewController?.present(bottomSheetViewController, animated: false)
  }
  
  private func showCategoryBottomSheet(
    animateCategoryHandler: @escaping ProductViewModelActions.AnimateCategoryHandler,
    passCategoryHandler: @escaping ProductViewModelActions.PassCategoryHandler
  ) {
    let bottomSheetViewController = self.dependencies.makeBottomSheetViewController(
      detent: .large
    )
    bottomSheetViewController.dismissHandler = { [weak self] in
      animateCategoryHandler()
      self?.dismissCategoryBottomSheet()
    }
    
    self.bottomSheetViewController = bottomSheetViewController
    
    let actions = CategoryBottomSheetViewModelActions(passCategory: { [weak self] catrgory in
      passCategoryHandler(catrgory)
      self?.bottomSheetViewController?.hideBottomSheetAndDismiss()
    })
    let categoryBottomSheetViewController = self.dependencies.makeCategoryBottomSheetViewController(actions: actions)
    self.categoryBottomSheetViewController = categoryBottomSheetViewController
    
    bottomSheetViewController.add(
      child: categoryBottomSheetViewController,
      container: bottomSheetViewController.bottomSheetView
    )
    bottomSheetViewController.modalPresentationStyle = .overFullScreen
    self.navigationController?.topViewController?.present(bottomSheetViewController, animated: false)
  }
  
  private func dismissPhotoBottomSheet() {
    self.photoBottomSheetViewController?.remove()
    self.bottomSheetViewController?.dismiss(animated: false)
    self.photoBottomSheetViewController = nil
    self.bottomSheetViewController = nil
  }
  
  private func dismissCategoryBottomSheet() {
    self.categoryBottomSheetViewController?.remove()
    self.bottomSheetViewController?.dismiss(animated: false)
    self.categoryBottomSheetViewController = nil
    self.bottomSheetViewController = nil
  }
}
