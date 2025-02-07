//
//  DateTimeSettingViewModel.swift
//  FreshNote
//
//  Created by SeokHyun on 10/23/24.
//

import Combine
import Foundation

struct DateTimeSettingViewModelActions {
  /// start에서만 사용
  let showHome: () -> Void
  /// edit에서만 사용
  let pop: () -> Void
}

protocol DateTimeSettingViewModelInput {
  func viewDidLoad()
  func didTapCompletionButton(dateInt: Int, hourMinuteDate: Date)
  func viewWillDisappear()
}

protocol DateTimeSettingViewModelOutput {
  var errorPublisher: AnyPublisher<(any Error)?, Never> { get }
  var dateTimePublisher: AnyPublisher<DateTime, Never> { get }
}

protocol DateTimeSettingViewModel: DateTimeSettingViewModelInput, DateTimeSettingViewModelOutput {
  
}

enum DateTimeSettingViewModelMode {
  case edit
  case start
}

final class DefaultDateTimeSettingViewModel: DateTimeSettingViewModel {
  // MARK: - Properties
  private let actions : DateTimeSettingViewModelActions
  private var subscriptions = Set<AnyCancellable>()
  
  private let mode: DateTimeSettingViewModelMode
  private let saveDateTimeUseCase: (any SaveDateTimeUseCase)?
  private let updateDateTimeUseCase: (any UpdateDateTimeUseCase)?
  private let fetchDateTimeUseCase: (any FetchDateTimeUseCase)?
  private let updatePushNotificationUseCase: (any UpdatePushNotificationUseCase)?
  
  // MARK: - Output
  var errorPublisher: AnyPublisher<(any Error)?, Never> { self.$error.eraseToAnyPublisher() }
  var dateTimePublisher: AnyPublisher<DateTime, Never> { self.dateTimeSubject.eraseToAnyPublisher() }

  @Published private var error: (any Error)?
  private let dateTimeSubject: PassthroughSubject<DateTime, Never> = .init()
  
  // MARK: - LifeCycle
  /// mode: start
  init(
    actions: DateTimeSettingViewModelActions,
    mode: DateTimeSettingViewModelMode,
    saveDateTimeUseCase: any SaveDateTimeUseCase
  ) {
    self.actions = actions
    self.mode = mode
    self.saveDateTimeUseCase = saveDateTimeUseCase
    self.updateDateTimeUseCase = nil
    self.fetchDateTimeUseCase = nil
    self.updatePushNotificationUseCase = nil
  }
  
  /// mode: edit
  init(
    actions: DateTimeSettingViewModelActions,
    mode: DateTimeSettingViewModelMode,
    updateDateTimeUseCase: any UpdateDateTimeUseCase,
    fetchDateTimeUseCase: any FetchDateTimeUseCase,
    updatePushNotificationUseCase: any UpdatePushNotificationUseCase
  ) {
    self.actions = actions
    self.mode = mode
    self.updateDateTimeUseCase = updateDateTimeUseCase
    self.fetchDateTimeUseCase = fetchDateTimeUseCase
    self.saveDateTimeUseCase = nil
    self.updatePushNotificationUseCase = updatePushNotificationUseCase
  }
  
  deinit {
    print("DEBUG: \(Self.self) deinit")
  }
  
  // MARK: - Private
  
  // MARK: - Input
  func viewDidLoad() {
    if case .edit = self.mode,
       let fetchDateTimeUseCase = self.fetchDateTimeUseCase {
      fetchDateTimeUseCase
        .execute()
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
          guard case .failure(let error) = completion else { return }
          self?.error = error
        } receiveValue: { [weak self] dateTime in
          self?.dateTimeSubject.send(dateTime)
        }
        .store(in: &self.subscriptions)
    }
  }
  
  func didTapCompletionButton(dateInt: Int, hourMinuteDate: Date) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HH:mm"
    let selectedTime = hourMinuteDate
    let hourMinute = dateFormatter.string(from: selectedTime).components(separatedBy: ":").map { Int($0) ?? 0 }
    let hour = hourMinute.first ?? 0, minute = hourMinute.last ?? 0
    
    switch self.mode {
    case .edit:
      guard let updateDateTimeUseCase = self.updateDateTimeUseCase else { return }
      
      // 이 시점은, localDB에 products save 호출이 보장되기 때문에, fetchProductUseCase를 통해서
      updateDateTimeUseCase
        .execute(dateTime: DateTime(date: dateInt, hour: hour, minute: minute))
        .flatMap { [weak self] _ -> AnyPublisher<Void, any Error> in
          guard let updatePushNotificationUseCase = self?.updatePushNotificationUseCase else {
            return Fail(error: CommonError.referenceError).eraseToAnyPublisher()
          }
          
          return updatePushNotificationUseCase
            .updateNotifications()
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
          guard case .failure(let error) = completion else { return }
          self?.error = error
        } receiveValue: { [weak self] _ in
          self?.actions.pop()
        }
        .store(in: &self.subscriptions)

    case .start:
      guard let saveDateTimeUseCase = self.saveDateTimeUseCase else { return }
      
      saveDateTimeUseCase
        .saveDateTime(date: dateInt, hour: hour, minute: minute)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
          guard case .failure(let error) = completion else { return }
          self?.error = error
          
        } receiveValue: { [weak self] _ in
          self?.actions.showHome()
        }
        .store(in: &subscriptions)
    }
  }
  
  func viewWillDisappear() {
    if case .edit = self.mode {
      self.actions.pop()
    }
  }
}
