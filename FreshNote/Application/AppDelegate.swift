//
//  AppDelegate.swift
//  FreshNote
//
//  Created by SeokHyun on 10/19/24.
//

import UIKit
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
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
  }
  
  // 사용자가 알림을 터치하면 호출되는 메소드
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    // 해당 제품에 대한 화면으로 이동하자
  }
}
