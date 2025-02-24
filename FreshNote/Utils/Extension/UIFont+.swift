//
//  UIFont+.swift
//  FreshNote
//
//  Created by SeokHyun on 10/22/24.
//

import UIKit

extension UIFont {
  /// Font의 이름을 프린팅해주는 메소드입니다.
  /// 커스텀 Font의 이름을 확인할 때 사용합니다.
  static func checkFont() {
    for family in UIFont.familyNames {
      print("family: \(family)")
      for name in UIFont.fontNames(forFamilyName: family) {
        print("name: \(name)")
      }
    }
  }
  
  /// pretendard의 font를 적용할 때 사용하는 메소드입니다.
  static func pretendard(size fontSize: CGFloat, weight weightString: FNFontWeight) -> UIFont {
    let familyName = "PretendardVariable"
    
    return UIFont(name: familyName + "-" + weightString.rawValue, size: fontSize) ??
    UIFont.systemFont(ofSize: fontSize, weight: .regular)
  }
}

enum FNFontWeight: String {
  case _100 = "Thin"
  case _200 = "ExtraLight"
  case _300 = "Light"
  case _400 = "Regular"
  case _500 = "Medium"
  case _600 = "SemiBold"
  case _700 = "Bold"
  case _800 = "Heavy"
  case _900 = "Black"
}
