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
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
   
    let center = UNUserNotificationCenter.current()

    let options = UNAuthorizationOptions(arrayLiteral: [.badge, .sound])
    center.requestAuthorization(options: options) { success, error in
      if let error = error {
        print("에러 발생: \(error.localizedDescription)")
      }
    }
    
    return true
  }
}
