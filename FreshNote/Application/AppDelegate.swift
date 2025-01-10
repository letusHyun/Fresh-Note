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
    
    return true
  }
}
//
//// MARK: - Private Helpers
//private extension AppDelegate {
////  func setupFCM(_ application: UIApplication) {
////    Messaging.messaging().delegate = self
////    UNUserNotificationCenter.current().delegate = self
////    UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert, .badge]) { isAgree, error in
////      if isAgree {
////        print("알림허용")
////      }
////    }
////    application.registerForRemoteNotifications()
////  }
//}
//
//// MARK: - UNUserNotificationCenterDelegate
//extension AppDelegate: UNUserNotificationCenterDelegate {
//    /// 푸시클릭시
//    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
//      let userInfo = response.notification.request.content.userInfo
//              print(userInfo)
//              print(userInfo["url"] as? String)
//              guard let deepLinkUrl = userInfo["url"] as? String,
//                  let url = URL(string: deepLinkUrl) else { return }
//
//              // 해당 host를 가지고 있는지 확인
//              guard url.host == "navigation" else { return }
//
//              // 원하는 query parameter가 있는지 확인
//              let urlString = url.absoluteString
//              guard urlString.contains("name") else { return }
//
//              // URL을 URLComponent로 만들어서 parameter값 가져오기 쉽게 접근
//              let components = URLComponents(string: urlString)
//
//              // URLQueryItem 형식은 [name: value] 쌍으로 되어있으서 Dctionary로 변형
//              let urlQueryItems = components?.queryItems ?? []
//              var dictionaryData = [String: String]()
//              urlQueryItems.forEach { dictionaryData[$0.name] = $0.value }
//              guard let name = dictionaryData["name"] else { return }
//
//              print("네임 = \(name)")
//    }
//    
//    /// 앱화면 보고있는중에 푸시올 때
//    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
//        print("🟢", #function)
//        return [.sound, .banner, .list]
//    }
//    
//    /// 스위즐링 NO시, APNs등록, 토큰값가져옴
//    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        Messaging.messaging().apnsToken = deviceToken
//        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
//        print("🟢", #function, deviceTokenString)
//    }
//    
//    /// error발생시
//    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
//        print("🟢", error)
//    }
//}
