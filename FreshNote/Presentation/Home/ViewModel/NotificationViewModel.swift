//
//  NotificationViewModel.swift
//  FreshNote
//
//  Created by SeokHyun on 10/31/24.
//

import Foundation
import Combine

struct NotificationViewModelActions {
  let pop: () -> Void
}

protocol NotificationViewModel: NotificaionViewModelInput, NotificationViewModelOutput { }

protocol NotificaionViewModelInput {
  func viewDidLoad()
  func numberOfRowsInSection() -> Int
  func cellForRow(at indexPath: IndexPath) -> ProductNotification
  func didSelectRow(at indexPath: IndexPath)
  func didTapBackButton()
}

protocol NotificationViewModelOutput {
  var reloadDataPublisher: AnyPublisher<Void, Never> { get }
  var reloadRowPublisher: AnyPublisher<IndexPath, Never> { get }
  var errorPublisher: AnyPublisher<(any Error)?, Never> { get }
}

final class DefaultNotificationViewModel: NotificationViewModel {
  // MARK: - Properties
  private var notifications: [ProductNotification] = []
  private let actions: NotificationViewModelActions
  private let productNotificationUseCase: any ProductNotificationUseCase
  private var subscriptions = Set<AnyCancellable>()
  
  // MARK: - Output
  private let reloadDataSubject = PassthroughSubject<Void, Never>()
  private let reloadRowSubject = PassthroughSubject<IndexPath, Never>()
  @Published private var error: (any Error)?
  
  var reloadDataPublisher: AnyPublisher<Void, Never> {
    self.reloadDataSubject.eraseToAnyPublisher()
  }
  var reloadRowPublisher: AnyPublisher<IndexPath, Never> {
    self.reloadRowSubject.eraseToAnyPublisher()
  }
  var errorPublisher: AnyPublisher<(any Error)?, Never> { self.$error.eraseToAnyPublisher() }
  
  // MARK: - LifeCycle
  init(
    actions: NotificationViewModelActions,
    productNotificationUseCase: any ProductNotificationUseCase
  ) {
    self.actions = actions
    self.productNotificationUseCase = productNotificationUseCase
  }
  // MARK: - Input
  func viewDidLoad() {
    self.productNotificationUseCase
      .fetchProductNotifications()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] completion in
        guard case .failure(let error) = completion else { return }
        self?.error = error
      } receiveValue: { [weak self] productNotifications in
        self?.notifications = productNotifications
        self?.reloadDataSubject.send()
      }
      .store(in: &self.subscriptions)
  }
  
  func numberOfRowsInSection() -> Int {
    return self.notifications.count
  }
  
  func cellForRow(at indexPath: IndexPath) -> ProductNotification {
    return self.notifications[indexPath.row]
  }
  
  func didSelectRow(at indexPath: IndexPath) {
    guard !self.notifications[indexPath.row].isViewed else { return }
    // fetch api
        // 성공 시, 서버는 저장만 함
    
    // 성공 시
    self.notifications[indexPath.row].isViewed.toggle()
    self.reloadDataSubject.send()
  }
  
  func didTapBackButton() {
    self.actions.pop()
  }
}
