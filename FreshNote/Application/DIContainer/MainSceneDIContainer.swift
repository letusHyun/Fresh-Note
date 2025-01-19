//
//  MainSceneDIContainer.swift
//  FreshNote
//
//  Created by SeokHyun on 10/28/24.
//

import UIKit

final class MainSceneDIContainer {
  struct Dependencies {
    // service객체
  }
  
  // MARK: - Properties
  private let dependencies: Dependencies
  
  // MARK: - LifeCycle
  init(dependencies: Dependencies) {
    self.dependencies = dependencies
  }
}

private extension MainSceneDIContainer {
  // MARK: - Presentation Layer
  func makeHomeViewModel(actions: HomeViewModelActions) -> any HomeViewModel {
    return DefaultHomeViewModel(
      actions: actions,
      fetchProductUseCase: self.makefetchProductUseCase(),
      deleteProductUseCase: self.makeDeleteProductUseCase(),
      updateProductUseCase: self.makeUpdateProductUseCase(),
      restorePushNotificationsUseCase: self.makeRestorePushNotificationsUseCase()
    )
  }
  
  func makeCalendarViewModel(actions: CalendarViewModelActions) -> any CalendarViewModel {
    return DefaultCalendarViewModel(actions: actions, fetchProductUseCase: self.makefetchProductUseCase())
  }
  
  func makeNotificationViewModel(actions: NotificationViewModelActions) -> any NotificationViewModel {
    return DefaultNotificationViewModel(
      actions: actions,
      productNotificationUseCase: self.makeProductNotificationUseCase()
    )
  }
  
  func makeSearchViewModel(actions: SearchViewModelActions) -> any SearchViewModel {
    return DefaultSearchViewModel(
      actions: actions,
      recentProductQueriesUseCase: self.makeRecentProductQueriesUseCase(),
      fetchProductUseCase: self.makefetchProductUseCase(),
      updateProductUseCase: self.makeUpdateProductUseCase()
    )
  }
  
  func makeProductViewModel(actions: ProductViewModelActions, mode: ProductViewModelMode) -> any ProductViewModel {
    return DefaultProductViewModel(
      saveProductUseCase: self.makeSaveProductUseCase(),
      updateProductUseCase: self.makeUpdateProductUseCase(),
      fetchProductUseCase: self.makefetchProductUseCase(),
      actions: actions,
      mode: mode
    )
  }
  
  func makePhotoBottomSheetViewModel(actions: PhotoBottomSheetViewModelActions) -> any PhotoBottomSheetViewModel {
    return DefaultPhotoBottomSheetViewModel(actions: actions)
  }
  
  func makeCategoryBottomSheetViewModel(
    actions: CategoryBottomSheetViewModelActions
  ) -> any CategoryBottomSheetViewModel {
    return DefaultCategoryBottomSheetViewModel(actions: actions)
  }
  
  func makePinViewModel(actions: PinViewModelActions) -> any PinViewModel {
    return DefaultPinViewModel(
      actions: actions,
      fetchProductUseCase: self.makefetchProductUseCase(),
      updateProductUseCase: self.makeUpdateProductUseCase()
    )
  }
  
  func makeCategoryViewModel(actions: CategoryViewModelActions) -> any CategoryViewModel {
    return DefaultCategoryViewModel(actions: actions)
  }
  
  func makeCategoryDetailViewModel(
    actions: CategoryDetailViewModelActions,
    category: ProductCategory
  ) -> any CategoryDetailViewModel {
    return DefaultCategoryDetailViewModel(
      actions: actions,
      category: category,
      fetchProductUseCase: self.makefetchProductUseCase(),
      updateProductUseCase: self.makeUpdateProductUseCase()
    )
  }
  
  func makeSettingViewModel(actions: SettingViewModelActions) -> any SettingViewModel {
    DefaultSettingViewModel(actions: actions)
  }
  
  func makeDateTimeSettingViewModel(
    actions: DateTimeSettingViewModelActions,
    mode: DateTimeSettingViewModelMode
  ) -> any DateTimeSettingViewModel {
    return DefaultDateTimeSettingViewModel(
      actions: actions,
      mode: mode,
      updateDateTimeUseCase: self.makeUpdateDateTimeUseCase(),
      fetchDateTimeUseCase: self.makeFetchDateTimeUseCase(),
      updatePushNotificationUseCase: self.makeUpdateAllPushNotificationsUseCase()
    )
  }
  
  func makeSignOutAlertViewModel(
    actions: SignOutAlertViewModelActions
  ) -> any SignOutAlertViewModel {
    return DefaultSignOutAlertViewModel(actions: actions)
  }
  
  // MARK: - Domain Layer
  func makeUpdateDateTimeUseCase() -> any UpdateDateTimeUseCase {
    DefaultUpdateTimeUseCase(dateTimeRepository: self.makeDateTimeRepository())
  }
  
  func makeProductNotificationUseCase() -> any ProductNotificationUseCase {
    return DefaultProductNotificaionUseCase(
      productNotificationRepository: self.makeProductNotificationRepository()
    )
  }
  
  func makeRestorePushNotificationsUseCase() -> any RestorePushNotificationsUseCase {
    return DefaultRestorePushNotificationsUseCase(
      fetchDateTimeUseCase: self.makeFetchDateTimeUseCase(),
      checkRestorePushNotificationsUseCase: self.makeCheckRestorePushNotificationsUseCase(),
      pushNotificationRepository: self.makePushNotificationRepository()
    )
  }
  
  func makeCheckRestorePushNotificationsUseCase() -> any CheckRestorePushNotificationsUseCase {
    return DefaultCheckRestorePushNotificationsUseCase(
      productRepository: self.makeProductRepository(),
      pushNotificationRepository: self.makePushNotificationRepository()
    )
  }
  
  func makeRecentProductQueriesUseCase() -> any RecentProductQueriesUseCase {
    return DefaultRecentProductQueriesUseCase(productQueriesRepository: self.makeProductQueriesRepository())
  }
  
  func makeUpdateProductUseCase() -> any UpdateProductUseCase {
    return DefaultUpdateProductUseCase(
      productRepository: self.makeProductRepository(),
      imageRepository: self.makeImageRepository(),
      updatePushNotificationUseCase: self.makeUpdatePushNotificationUseCase()
    )
  }
  
  func makeUpdatePushNotificationUseCase() -> any UpdatePushNotificationUseCase {
    return DefaultUpdatePushNotificationUseCase(
      savePushNotificationUseCase: self.makeSavePushNotificationUseCase(),
      deletePushNotificationUseCase: self.makeDeletePushNotificationUseCase()
    )
  }
  
  func makeUpdateAllPushNotificationsUseCase() -> any UpdatePushNotificationUseCase {
    return DefaultUpdatePushNotificationUseCase(
      savePushNotificationUseCase: self.makeSavePushNotificationUseCase(),
      deletePushNotificationUseCase: self.makeDeletePushNotificationUseCase(),
      fetchProductUseCase: self.makefetchProductUseCase()
    )
  }
  
  func makeDeleteProductUseCase() -> any DeleteProductUseCase {
    return DefaultDeleteProductUseCase(
      imageRepository: self.makeImageRepository(),
      productRepository: self.makeProductRepository(),
      deletePushNotificationUseCase: self.makeDeletePushNotificationUseCase()
    )
  }
  
  func makeSaveProductUseCase() -> any SaveProductUseCase {
    return DefaultSaveProductUseCase(
      productRepository: self.makeProductRepository(),
      imageRepository: self.makeImageRepository(),
      savePushNotificationUseCase: self.makeSavePushNotificationUseCase()
    )
  }
  
  func makefetchProductUseCase() -> any FetchProductUseCase {
    return DefaultFetchProductUseCase(productRepository: self.makeProductRepository())
  }
  
  func makeSavePushNotificationUseCase() -> any SavePushNotificationUseCase {
    return DefaultSavePushNotificationUseCase(
      fetchDateTimeUseCase: self.makeFetchDateTimeUseCase(),
      pushNotificationRepository: self.makePushNotificationRepository()
    )
  }
  
  func makeFetchDateTimeUseCase() -> any FetchDateTimeUseCase {
    return DefaultFetchDateTimeUseCase(dateTimeRepository: self.makeDateTimeRepository())
  }
  
  // MARK: - Data Layer
  func makeProductNotificationRepository() -> any ProductNotificationRepository {
    return DefaultProductNotificationRepository(
      productNotificationStorage: self.makeProductNotificationStorage()
    )
  }
  
  func makeDeletePushNotificationUseCase() -> any DeletePushNotificationUseCase {
    return DefaultDeletePushNotificationUseCase(
      pushNotificationRepository: self.makePushNotificationRepository()
    )
  }
  
  func makeDateTimeRepository() -> DateTimeRepository {
    return DefaultDateTimeRepository(
      firebaseNetworkService: self.makeFirebaseNetworkService(),
      dateTimeStorage: self.makeDateTimeStorage()
    )
  }
  
  func makeProductQueriesRepository() -> any ProductQueriesRepository {
    return DefaultProductQueriesRepository(productQueryPersistentStorage: self.makeProductQueryStorage())
  }
  
  func makeProductRepository() -> any ProductRepository {
    return DefaultProductRepository(
      firebaseNetworkService: self.makeFirebaseNetworkService(),
      productStorage: self.makeProductStorage()
    )
  }
  
  func makePushNotificationRepository() -> any PushNotificationRepository {
    return DefaultPushNotificationRepository()
  }
  
  func makeImageRepository() -> any ImageRepository {
    return DefaultImageRepository(firebaseNetworkService: self.makeFirebaseNetworkService())
  }
  
  func makeFirebaseNetworkService() -> any FirebaseNetworkService {
    return DefaultFirebaseNetworkService()
  }
  
  // MARK: - Persistent Storage
  func makeProductNotificationStorage() -> ProductNotificationStorage {
    return CoreDataProductNotificationStorage(coreDataStorage: self.makeCoreDataStorage())
  }
  
  func makeProductQueryStorage() -> any ProductQueryStorage {
    return CoreDataProductQueryStorage(coreDataStorage: self.makeCoreDataStorage())
  }
  
  func makeDateTimeStorage() -> any DateTimeStorage {
    return CoreDataDateTimeStorage(coreDataStorage: self.makeCoreDataStorage())
  }
  
  func makeProductStorage() -> any ProductStorage {
    return CoreDataProductStorage(coreDataStorage: self.makeCoreDataStorage())
  }
  
  func makeCoreDataStorage() -> any CoreDataStorage {
    return PersistentCoreDataStorage.shared
  }
}

// MARK: - MainCoordinatorDependencies
extension MainSceneDIContainer: MainCoordinatorDependencies {
  func makeSettingCoordinator(navigationController: UINavigationController) -> SettingCoordinator {
    return SettingCoordinator(navigationController: navigationController, dependencies: self)
  }
  
  func makeCategoryCoordinator(navigationController: UINavigationController) -> CategoryCoordinator {
    return CategoryCoordinator(navigationController: navigationController, dependencies: self)
  }
  
  func makePinCoordinator(navigationController: UINavigationController) -> PinCoordinator {
    return PinCoordinator(navigationController: navigationController, dependencies: self)
  }
  
  func makeCalendarCoordinator(navigationController: UINavigationController) -> CalendarCoordinator {
    return CalendarCoordinator(navigationController: navigationController, dependencies: self)
  }
  
  func makeHomeCoordinator(navigationController: UINavigationController) -> HomeCoordinator {
    return HomeCoordinator(navigationController: navigationController, dependencies: self)
  }
}

// MARK: - SettingCoordinatorDependencies
extension MainSceneDIContainer: SettingCoordinatorDependencies {
  func makeSignOutAlertViewController(actions: SignOutAlertViewModelActions) -> SignOutAlertViewController {
    SignOutAlertViewController(viewModel: self.makeSignOutAlertViewModel(actions: actions))
  }
  
  func makeSettingViewController(actions: SettingViewModelActions) -> SettingViewController {
    SettingViewController(viewModel: self.makeSettingViewModel(actions: actions))
  }
  
  func makeDateTimeSettingCoordinator(navigationController: UINavigationController?) -> DateTimeSettingCoordinator {
    DateTimeSettingCoordinator(dependencies: self, navigationController: navigationController)
  }
}

// MARK: - DateTimeSettingCoordinatorDependencies
extension MainSceneDIContainer: DateTimeSettingCoordinatorDependencies {
  func makeDateTimeSettingViewController(
    actions: DateTimeSettingViewModelActions,
    mode: DateTimeSettingViewModelMode
  ) -> DateTimeSettingViewController {
    DateTimeSettingViewController(
      viewModel: self.makeDateTimeSettingViewModel(actions: actions, mode: mode),
      mode: mode
    )
  }
}

// MARK: - PinCoordinatorDependencies
extension MainSceneDIContainer: PinCoordinatorDependencies {
  func makePinViewController(actions: PinViewModelActions) -> PinViewController {
    return PinViewController(viewModel: self.makePinViewModel(actions: actions))
  }
  
  func makeProductCoordinator(
    navigationController: UINavigationController,
    productID: DocumentID
  ) -> ProductCoordinator {
    return ProductCoordinator(
      dependencies: self,
      navigationController: navigationController,
      mode: .edit(productID)
    )
  }
}

// MARK: - HomeCoordinatorDependencies
extension MainSceneDIContainer: HomeCoordinatorDependencies {
  func makeProductCoordinator(
    navigationController: UINavigationController?,
    mode: ProductViewModelMode
  ) -> ProductCoordinator {
    return ProductCoordinator(
      dependencies: self,
      navigationController: navigationController,
      mode: mode
    )
  }
  
  func makeSearchCoordinator(navigationController: UINavigationController?) -> SearchCoordinator {
    return SearchCoordinator(dependencies: self, navigationController: navigationController)
  }
  
  func makeNotificationCoordinator(navigationController: UINavigationController?) -> NotificationCoordinator {
    return NotificationCoordinator(dependencies: self, navigationController: navigationController)
  }
  
  func makeHomeViewController(actions: HomeViewModelActions) -> HomeViewController {
    return HomeViewController(viewModel: self.makeHomeViewModel(actions: actions))
  }
}

// MARK: - CalendarCoordinatorDependencies
extension MainSceneDIContainer: CalendarCoordinatorDependencies {
  func makeProductCoordinator(
    navigationController: UINavigationController?,
    productID: DocumentID
  ) -> ProductCoordinator {
    return self.makeProductCoordinator(navigationController: navigationController, mode: .edit(productID))
  }
  
  func makeCalendarViewController(actions: CalendarViewModelActions) -> CalendarViewController {
    return CalendarViewController(viewModel: self.makeCalendarViewModel(actions: actions))
  }
}

// MARK: - CategoryCoordinatorDependencies
extension MainSceneDIContainer: CategoryCoordinatorDependencies {
  func makeCategoryDetailCoordinator(
    navigationController: UINavigationController?,
    category: ProductCategory
  ) -> CategoryDetailCoordinator {
    return CategoryDetailCoordinator(
      navigationController: navigationController, category: category,
      dependencies: self
    )
  }
  
  func makeCategoryViewController(actions: CategoryViewModelActions) -> CategoryViewController {
    return CategoryViewController(viewModel: self.makeCategoryViewModel(actions: actions))
  }
}

// MARK: - NotificationCoordinatorDependencies
extension MainSceneDIContainer: NotificationCoordinatorDependencies {
  func makeNotificationViewController(actions: NotificationViewModelActions) -> NotificationViewController {
    return NotificationViewController(viewModel: self.makeNotificationViewModel(actions: actions))
  }
}

// MARK: - SearchCoordinatorDependencies
extension MainSceneDIContainer: SearchCoordinatorDependencies {
  func makeSearchViewController(actions: SearchViewModelActions) -> SearchViewController {
    return SearchViewController(viewModel: self.makeSearchViewModel(actions: actions))
  }
}

// MARK: - ProductCoordinatorDependencies
extension MainSceneDIContainer: ProductCoordinatorDependencies {
  func makeCategoryBottomSheetViewController(actions: CategoryBottomSheetViewModelActions) -> UIViewController {
    return CategoryBottomSheetViewController(viewModel: self.makeCategoryBottomSheetViewModel(actions: actions))
  }
  
  func makeBottomSheetViewController(
    detent: BottomSheetViewController.Detent
  ) -> BottomSheetViewController {
    return BottomSheetViewController(detent: detent)
  }
  
  func makePhotoBottomSheetViewController(actions: PhotoBottomSheetViewModelActions) -> UIViewController {
    return PhotoBottomSheetViewController(viewModel: self.makePhotoBottomSheetViewModel(actions: actions))
  }
  
  func makeProductViewController(
    actions: ProductViewModelActions,
    mode: ProductViewModelMode
  ) -> ProductViewController {
    return ProductViewController(viewModel: self.makeProductViewModel(actions: actions, mode: mode))
  }
}

// MARK: - CategoryDetailCoordinatorDependencies
extension MainSceneDIContainer: CategoryDetailCoordinatorDependencies {
  func makeCategoryDetailViewController(
    actions: CategoryDetailViewModelActions,
    category: ProductCategory
  ) -> CategoryDetailViewController {
    CategoryDetailViewController(viewModel: self.makeCategoryDetailViewModel(actions: actions,
                                                                             category: category))
  }
}
