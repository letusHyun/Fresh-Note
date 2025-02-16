////
////  PhotoDetailCoordinator.swift
////  FreshNote
////
////  Created by SeokHyun on 2/13/25.
////
//
//import UIKit
//
//protocol PhotoDetailCoordinatorDependencies: AnyObject {
//  func makePhotoDetailViewController(productID: DocumentID) -> PhotoDetailViewController
//}
//
//final class PhotoDetailCoordinator: BaseCoordinator {
//  // MARK: - Properties
//  private let productID: DocumentID
//  private let dependencies: any PhotoDetailCoordinatorDependencies
//  
//  // MARK: - LifeCycle
//  init(
//    navigationController: UINavigationController?,
//    dependencies: any PhotoDetailCoordinatorDependencies,
//    productID: DocumentID
//  ) {
//    self.productID = productID
//    self.dependencies = dependencies
//    
//    super.init(navigationController: navigationController)
//  }
//  // MARK: - Start
//  func start() {
//    let viewController = self.dependencies.makePhotoDetailViewController(productID: self.productID)
//    self.navigationController?.pushViewController(viewController, animated: true)
//  }
//}
