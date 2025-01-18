//
//  SettingEmptyView.swift
//  FreshNote
//
//  Created by SeokHyun on 1/17/25.
//

import Foundation
import UIKit

final class SettingEmptyView: UITableViewHeaderFooterView {
  // MARK: - Properties
  static var id: String {
    String(describing: Self.self)
  }
  
  // MARK: - LifeCycle
  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    self.setupStyle()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - SetupUI
  private func setupStyle() {
    self.contentView.backgroundColor = UIColor(hex: "#EEEEEE")
  }
}
