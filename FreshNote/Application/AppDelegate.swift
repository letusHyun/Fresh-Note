//
//  AppDelegate.swift
//  FreshNote
//
//  Created by SeokHyun on 10/19/24.
//

import Combine
import UIKit

import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  private lazy var productNotificationUseCase: any ProductNotificationUseCase = {
    let repository = DefaultProductNotificationRepository(
      productNotificationStorage: CoreDataProductNotificationStorage(
        coreDataStorage: PersistentCoreDataStorage.shared
      )
    )
    return DefaultProductNotificaionUseCase(productNotificationRepository: repository)
  }()
  
  private var cancellable: Set<AnyCancellable> = []
  
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    // 알림 센터 가져오기
    let center = UNUserNotificationCenter.current()
    center.delegate = self
    
    let options = UNAuthorizationOptions(arrayLiteral: [.badge, .sound])
    center.requestAuthorization(options: options) { success, error in
      if let error = error {
        print("에러 발생: \(error.localizedDescription)")
      }
    }
    
    Future<[UNNotification], Never> { promise in
      UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
        promise(.success(notifications))
      }
    }
    .flatMap { notifications -> Publishers.Sequence<[UNNotification], Never> in
      Publishers.Sequence(sequence: notifications)
    }
    .flatMap(maxPublishers: .max(3)) { [weak self] unNotification -> AnyPublisher<Void, any Error> in
      guard let self  else { return Empty().eraseToAnyPublisher() }
      let (productName, remainingDay) = NotificationHelper
        .extractTitleAndDay(from: unNotification.request.content.body
        ) ?? ("", 0)
      let productNotification = ProductNotification(
        productName: productName,
        remainingDay: remainingDay,
        isViewed: false
      )
      
      return self.productNotificationUseCase.saveProductNotification(productNotification)
    }
    .receive(on: DispatchQueue.main)
    .sink { _ in
      
    } receiveValue: { _ in
      UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    .store(in: &self.cancellable)
    return true
  }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
  // foreground에 존재할 때 알림이 오면 호출되는 메소드
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions
    ) -> Void) {
    completionHandler([.banner, .badge, .sound, .list])
    
    UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
      print("foreground 시점 getDeliveredNotifications: \(notifications)")
    }
  }
  
  // 사용자가 알림을 터치하면 호출되는 메소드
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
      print("사용자가 알림을 터치했을 때의 getDeliveredNotifications: \(notifications)")
    }
  }
}
