//
//  SettingViewModel.swift
//  FreshNote
//
//  Created by SeokHyun on 1/16/25.
//

import Combine
import Foundation

struct SettingViewModelActions {
  let showDateTime: () -> Void
  let showDateTimeSetting: () -> Void
  let showAppGuide: () -> Void
  let showInquire: () -> Void
  let presentSignOutAlert: () -> Void
}

struct SettingMenuItem {
  let title: String
  let action: () -> Void
}

enum SettingSection {
  case account
  case settings
  case usage
  
  var title: String {
    switch self {
    case .account: return "계정"
    case .settings: return "설정"
    case .usage: return "이용안내"
    }
  }
}

struct SettingDataSource {
  let section: SettingSection
  let items: [SettingMenuItem]
}

protocol SettingViewModel: SettingViewModelInput, SettingViewModelOutput { }

protocol SettingViewModelInput {
  func viewDidLoad()
  func didSelectRow(at indexPath: IndexPath)
  func cellForItem(at indexPath: IndexPath) -> String
  func numberOfSections() -> Int
  func numberOfRows(in section: Int) -> Int
  func viewForHeader(in section: Int) -> String
  func heightForFooter(in section: Int) -> CGFloat
  func didTapCancelButton()
  func didTapSignOutButton()
}

protocol SettingViewModelOutput {
  
}

final class DefaultSettingViewModel: SettingViewModel {
  // MARK: - Properties
  private let actions: SettingViewModelActions
  
  private var dataSource: [SettingDataSource] = []
  
  // MARK: - Output
  
  // MARK: - LifeCycle
  init(actions: SettingViewModelActions) {
    self.actions = actions
    self.dataSource = self.makeDataSource()
  }
  
  // MARK: - Input
  func viewDidLoad() {
    
  }
  
  func numberOfSections() -> Int {
    self.dataSource.count
  }
  
  func numberOfRows(in section: Int) -> Int {
    self.dataSource[section].items.count
  }
  
  func didSelectRow(at indexPath: IndexPath) {
    self.dataSource[indexPath.section]
      .items[indexPath.item]
      .action()
  }
  
  func cellForItem(at indexPath: IndexPath) -> String {
    self.dataSource[indexPath.section]
      .items[indexPath.item]
      .title
  }
  
  func viewForHeader(in section: Int) -> String {
    self.dataSource[section].section.title
  }
  
  func heightForFooter(in section: Int) -> CGFloat {
    if section == self.dataSource.count - 1 {
      return 0
    }
    return 14
  }
  
  func didTapCancelButton() {
    
  }
  
  func didTapSignOutButton() {
    
  }
  
  // MARK: - Private
  private func makeDataSource() -> [SettingDataSource] {
    let logout = SettingMenuItem(title: "로그아웃", action: { [weak self] in self?.actions.presentSignOutAlert() })
    let accountSection = SettingDataSource(section: .account, items: [logout])
    
    let notification = SettingMenuItem(
      title: "알림 설정",
      action: { [weak self] in self?.actions.showDateTimeSetting() }
    )
    let settingSection = SettingDataSource(section: .settings, items: [notification])
    
    let appGuide = SettingMenuItem(title: "앱 가이드", action: { [weak self] in self?.actions.showAppGuide() })
    let inquire = SettingMenuItem(title: "문의하기", action: { [weak self] in self?.actions.showInquire() })
    let usageSection = SettingDataSource(section: .usage, items: [appGuide, inquire])
    
    return [accountSection, settingSection, usageSection]
  }
}
