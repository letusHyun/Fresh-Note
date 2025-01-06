//
//  CalendarViewModel.swift
//  FreshNote
//
//  Created by SeokHyun on 10/28/24.
//

import Combine
import Foundation

struct CalendarViewModelActions {
  let showProduct: (DocumentID) -> Void
}

protocol CalendarViewModelInput {
  func viewDidLoad()
  func viewWillAppear(calendarDateComponents: CalendarDateComponents)
  func cellForItem(at indexPath: IndexPath) -> Product
  func numberOfItemsInSection() -> Int
  func didSelectDate(calendarDateComponents: CalendarDateComponents)
  func didDeselectDate(calendarDateComponents: CalendarDateComponents)
  func didChangeVisibleDateComponents(calendarDateComponents: CalendarDateComponents)
  func didSelectItem(at indexPath: IndexPath)
}

protocol CalendarViewModelOutput {
  var errorPublisher: AnyPublisher<(any Error)?, Never> { get }
  var reloadDataPublisher: AnyPublisher<Void, Never> { get }
}

protocol CalendarViewModel: CalendarViewModelInput & CalendarViewModelOutput { }

final class DefaultCalendarViewModel: CalendarViewModel {
  // MARK: - Properties
  private let actions: CalendarViewModelActions
  
  private let fetchProductUseCase: any FetchProductUseCase
  
  private var subscriptions = Set<AnyCancellable>()
  
  @Published private var error: (any Error)?
  
  private var originDataSource = [Product]()
  
  private var filterdDataSource = [Product]()
  
  private let monthFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yy.MM"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "ko_KR")
    return formatter
  }()
  
  // MARK: - Output
  var reloadDataPublisher: AnyPublisher<Void, Never> { self.reloadDataSubject.eraseToAnyPublisher() }
  var errorPublisher: AnyPublisher<(any Error)?, Never> { self.$error.eraseToAnyPublisher() }
  
  private let reloadDataSubject: PassthroughSubject<Void, Never> = .init()
  
  // MARK: - LifeCycle
  init(
    actions: CalendarViewModelActions,
    fetchProductUseCase: any FetchProductUseCase
  ) {
    self.actions = actions
    self.fetchProductUseCase = fetchProductUseCase
  }
  
  // MARK: - Input
  func viewDidLoad() {
    
  }
  
  func cellForItem(at indexPath: IndexPath) -> Product {
    return self.filterdDataSource[indexPath.item]
  }
  
  func numberOfItemsInSection() -> Int {
    return self.filterdDataSource.count
  }
  
  func viewWillAppear(calendarDateComponents: CalendarDateComponents) {
    self.fetchProductUseCase
      .fetchProducts()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] completion in
        guard case .failure(let error) = completion else { return }
        self?.error = error
      } receiveValue: { [weak self] products in
        guard let self else { return }
        
        self.originDataSource = products
      
        switch calendarDateComponents {
        case let .day(dateComponents):
          self.filterToProductsBasedOnDay(dateComponents: dateComponents)
        case let .month(dateComponents):
          self.filterToProductsBasedOnMonth(dateComponents: dateComponents)
        case .currentMonth:
          self.filterToProductsBasedOnCurrentMonth(with: products)
        }
      }
      .store(in: &self.subscriptions)
  }
  
  func didChangeVisibleDateComponents(calendarDateComponents: CalendarDateComponents) {
    if case let .month(dateComponents) = calendarDateComponents {
      self.filterToProductsBasedOnMonth(dateComponents: dateComponents)
    }
  }
  
  func didSelectDate(calendarDateComponents: CalendarDateComponents) {
    if case let .day(dateComponents) = calendarDateComponents {
      self.filterToProductsBasedOnDay(dateComponents: dateComponents)
    }
  }
  
  func didDeselectDate(calendarDateComponents: CalendarDateComponents) {
    if case let .month(dateComponents) = calendarDateComponents {
      self.filterToProductsBasedOnMonth(dateComponents: dateComponents)
    }
  }
  
  func didSelectItem(at indexPath: IndexPath) {
    let productID = filterdDataSource[indexPath.item].did
    self.actions.showProduct(productID)
  }
  
  // MARK: - Private
  private func filterToProductsBasedOnCurrentMonth(with products: [Product]) {
    let currentDateString = self.monthFormatter.string(from: Date())
    
    self.filterdDataSource = products.filter {
      self.monthFormatter.string(from: $0.expirationDate) == currentDateString
    }
    
    self.reloadDataSubject.send()
  }
  
  private func filterToProductsBasedOnDay(dateComponents: DateComponents) {
    guard let date = dateComponents.date else { return }
    
    let dateFormatter = DateFormatManager()
    let selectedDateString = dateFormatter.string(from: date)
    
    self.filterdDataSource = self.originDataSource.filter {
      dateFormatter.string(from: $0.expirationDate) == selectedDateString
    }
    
    self.reloadDataSubject.send()
  }
  
  private func filterToProductsBasedOnMonth(dateComponents: DateComponents) {
    let year = String(format: "%02d", (dateComponents.year ?? .zero) % 100)
    let month = String(format: "%02d", dateComponents.month ?? .zero)
    let changedDateString = "\(year).\(month)"
  
    self.filterdDataSource = self.originDataSource.filter {
      self.monthFormatter.string(from: $0.expirationDate) == changedDateString
    }
    
    self.reloadDataSubject.send()
  }
}
