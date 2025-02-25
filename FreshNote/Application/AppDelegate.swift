//
//  AppDelegate.swift
//  FreshNote
//
//  Created by SeokHyun on 10/19/24.
//

import Combine
import UIKit
import UserNotifications

import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let firebaseConfigFile: String
#if DEBUG
    firebaseConfigFile = "GoogleService-Info-Debug"
#else
    firebaseConfigFile = "GoogleService-Info"
#endif
    if let path = Bundle.main.path(forResource: firebaseConfigFile, ofType: "plist"),
       let options = FirebaseOptions(contentsOfFile: path) {
      FirebaseApp.configure(options: options)
    }

    let center = UNUserNotificationCenter.current()
    center.delegate = self
    
    let options = UNAuthorizationOptions(arrayLiteral: [.badge, .sound])
    center.requestAuthorization(options: options) { success, error in
      if let error = error {
        print("에러 발생: \(error.localizedDescription)")
      }
    }
    
    return true
  }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
  // foreground 상태일 때 알림 뜰 때 호출되는 메소드
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .badge, .sound, .list])
  }
  
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
//    if let windowScene = UIApplication.shared.connectedScenes
//      .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
//       let sceneDelegate = windowScene.delegate as? SceneDelegate {
//      sceneDelegate.appCoordinator
//    }
  }
}
