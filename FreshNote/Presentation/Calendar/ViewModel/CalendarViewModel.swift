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
  func viewWillAppear()
  func cellForItem(at indexPath: IndexPath) -> Product
  func numberOfItemsInSection() -> Int
  func didSelectDate(dateComponents: DateComponents?)
  func didChangeVisibleDateComponents(dateComponents: DateComponents)
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
  
  func viewWillAppear() {
    self.fetchProductUseCase
      .fetchProducts()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] completion in
        guard case .failure(let error) = completion else { return }
        self?.error = error
      } receiveValue: { [weak self] products in
        guard let self else { return }
        
        self.originDataSource = products
        
        let currentDateString = self.monthFormatter.string(from: Date())
        
        self.filterdDataSource = products.filter {
          self.monthFormatter.string(from: $0.expirationDate) == currentDateString
        }
        
        self.reloadDataSubject.send()
      }
      .store(in: &self.subscriptions)
  }
  
  func didChangeVisibleDateComponents(dateComponents: DateComponents) {
    let year = String(format: "%02d", (dateComponents.year ?? .zero) % 100)
    let month = String(format: "%02d", dateComponents.month ?? .zero)
    let changedDateString = "\(year).\(month)"
  
    self.filterdDataSource = self.originDataSource.filter {
      self.monthFormatter.string(from: $0.expirationDate) == changedDateString
    }
    
    self.reloadDataSubject.send()
  }
  
  func didSelectDate(dateComponents: DateComponents?) {
    guard let date = dateComponents?.date else { return }
    
    let dateFormatter = DateFormatManager()
    let selectedDateString = dateFormatter.string(from: date)
    
    self.filterdDataSource = self.originDataSource.filter {
      dateFormatter.string(from: $0.expirationDate) == selectedDateString
    }
    
    self.reloadDataSubject.send()
  }
  
  func didSelectItem(at indexPath: IndexPath) {
    let productID = filterdDataSource[indexPath.item].did
    self.actions.showProduct(productID)
  }
}
