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
  func hasEvent(decorationFor date: Date) -> Bool
}

protocol CalendarViewModelOutput {
  var errorPublisher: AnyPublisher<(any Error)?, Never> { get }
  var reloadDataPublisher: AnyPublisher<Void, Never> { get }
  var reloadDecorationsPublisher: AnyPublisher<[DateComponents], Never> { get }
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
  
  private var currentMonthDateComponents: [DateComponents] = []
  
  // MARK: - Output
  var reloadDataPublisher: AnyPublisher<Void, Never> { self.reloadDataSubject.eraseToAnyPublisher() }
  var errorPublisher: AnyPublisher<(any Error)?, Never> { self.$error.eraseToAnyPublisher() }
  var reloadDecorationsPublisher: AnyPublisher<[DateComponents], Never> {
    self.reloadDecorationsSubject.eraseToAnyPublisher()
  }
  
  private let reloadDataSubject: PassthroughSubject<Void, Never> = .init()
  private let reloadDecorationsSubject: PassthroughSubject<[DateComponents], Never> = .init()
  
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
    let calendar = Calendar.current
    let now = Date()
    let currentYear = calendar.component(.year, from: now)
    let currentMonth = calendar.component(.month, from: now)

    self.updateDateComponentsForMonth(year: currentYear, month: currentMonth)
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
        
        let calendar = Calendar.current
        let dateComponents = self.originDataSource.map {
          calendar.dateComponents([.year, .month, .day], from: $0.expirationDate)
        }
        self.reloadDecorationsSubject.send(dateComponents)
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
  
  func hasEvent(decorationFor date: Date) -> Bool {
    let dateFormatter = DateFormatManager()
    let screenDateString = dateFormatter.makeYearMonthDay(date: date).joined(separator: ".")
    
    return self.filterdDataSource.contains { product in
      let expirationDateString = dateFormatter
        .makeYearMonthDay(date: product.expirationDate)
        .joined(separator: ".")

      return expirationDateString == screenDateString
    }
  }
  
  // MARK: - Private
  private func updateDateComponentsForMonth(year: Int, month: Int) {
    print("yaer: \(year), month: \(month)")
    let calendar = Calendar.current
    guard let firstDayOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))
    else { return }
    print("firstDayOfMonth: \(firstDayOfMonth)")
    
  }
  
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
