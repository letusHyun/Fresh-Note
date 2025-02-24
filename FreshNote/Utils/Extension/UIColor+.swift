//
//  UIColor+.swift
//  FreshNote
//
//  Created by SeokHyun on 10/22/24.
//

import UIKit

extension UIColor {
  /// hex와 alpha값을 설정하는 init입니다.
  convenience init(hex: String, alpha: CGFloat = 1.0) {
    let hexString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    let scanner = Scanner(string: hexString)
    
    if hexString.hasPrefix("#") {
      scanner.currentIndex = hexString.index(after: hexString.startIndex)
    }
    
    var color: UInt64 = 0
    scanner.scanHexInt64(&color)
  
    let r = (color & 0xff0000) >> 16
    let g = (color & 0x00ff00) >> 8
    let b = (color & 0x0000ff)
    
    self.init(red: CGFloat(r) / 0xff, green: CGFloat(g) / 0xff, blue: CGFloat(b) / 0xff, alpha: alpha)
  }
  
  /// FNColor를 통해 색상을 설정하고 alpha를 설정하는 init입니다.
  convenience init(fnColor: FNColor, alpha: CGFloat = 1.0) {
    let hexString: String = fnColor.rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    let scanner = Scanner(string: hexString)
    
    if hexString.hasPrefix("#") {
      scanner.currentIndex = hexString.index(after: hexString.startIndex)
    }
    
    var color: UInt64 = 0
    scanner.scanHexInt64(&color)
  
    let r = (color & 0xff0000) >> 16
    let g = (color & 0x00ff00) >> 8
    let b = (color & 0x0000ff)
    
    self.init(red: CGFloat(r) / 0xff, green: CGFloat(g) / 0xff, blue: CGFloat(b) / 0xff, alpha: alpha)
  }
}
