//
//  SearchViewModel.swift
//  FreshNote
//
//  Created by SeokHyun on 11/1/24.
//

import Combine
import Foundation

protocol SearchViewModel: SearchViewModelInput, SearchViewModelOutput,
                          SearchHistoryViewModelInput, SearchHistoryViewModelOutput,
                          SearchResultViewModelInput, SearchResultViewModelOutput { }

enum SearchViewModelType {
  case history
  case result
}

protocol SearchHistoryViewModelInput {
  func cellForRow(at indexPath: IndexPath) -> ProductQuery
  func didTapKeywordDeleteButton(at indexPath: IndexPath)
}

protocol SearchHistoryViewModelOutput {
  var historyDeleteRowsPublisher: AnyPublisher<IndexPath, Never> { get }
  var historyReloadDataPublisher: AnyPublisher<Void, Never> { get }
  var historyErrorPublisher: AnyPublisher<(any Error)?, Never> { get }
}

protocol SearchResultViewModelInput {
  func cellForRow(at indexPath: IndexPath) -> Product
}

protocol SearchResultViewModelOutput {
  var resultErrorPublisher: AnyPublisher<(any Error)?, Never> { get }
  var resultReloadDataPublisher: AnyPublisher<Void, Never> { get }
}

//protocol SearchViewModelCommonInput {
//  
//}

protocol SearchViewModelInput {
  func viewDidLoad()
  func didTapCancelButton()
  func numberOfRowsInSection(viewModelType: SearchViewModelType) -> Int
  func didSelectRow(at indexPath: IndexPath, viewModelType: SearchViewModelType)
  func textFieldShouldReturn(keyword: String)
}

protocol SearchViewModelOutput {

}

struct SearchViewModelActions {
  let pop: () -> Void
//  let showProduct: (String) -> Void
}

final class DefaultSearchViewModel: SearchViewModel {
  // MARK: - Properties
  private var productQueries: [ProductQuery] = []
  private var products: [Product] = []
  private let actions: SearchViewModelActions
  private let recentProductQueriesUseCase: any RecentProductQueriesUseCase
  private var subscriptions = Set<AnyCancellable>()
  
  // MARK: - Output
  var historyReloadDataPublisher: AnyPublisher<Void, Never> { self.historyReloadDataSubject.eraseToAnyPublisher() }
  var historyDeleteRowsPublisher: AnyPublisher<IndexPath, Never> {
    self.historyDeleteRowsSubject.eraseToAnyPublisher()
  }
  var historyErrorPublisher: AnyPublisher<(any Error)?, Never> { self.$historyError.eraseToAnyPublisher() }
  
  private let historyReloadDataSubject: PassthroughSubject<Void, Never> = .init()
  private let historyDeleteRowsSubject: PassthroughSubject<IndexPath, Never> = .init()
  @Published private var historyError: (any Error)?
  
  var resultErrorPublisher: AnyPublisher<(any Error)?, Never> { self.$resultError.eraseToAnyPublisher() }
  var resultReloadDataPublisher: AnyPublisher<Void, Never> { self.resultReloadDataSubject.eraseToAnyPublisher() }
  
  @Published private var resultError: (any Error)?
  private let resultReloadDataSubject: PassthroughSubject<Void, Never> = .init()
  
  // MARK: - LifeCycle
  init(
    actions: SearchViewModelActions,
    recentProductQueriesUseCase: any RecentProductQueriesUseCase
  ) {
    self.actions = actions
    self.recentProductQueriesUseCase = recentProductQueriesUseCase
  }

  // MARK: - Input
  func viewDidLoad() {
    self.recentProductQueriesUseCase.fetchQueries()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] completion in
        guard case .failure(let error) = completion else { return }
        self?.historyError = error
      } receiveValue: { [weak self] productQueries in
        self?.productQueries = productQueries
        self?.historyReloadDataSubject.send()
      }
      .store(in: &self.subscriptions)
  }
  
  func numberOfRowsInSection(viewModelType: SearchViewModelType) -> Int {
    switch viewModelType {
    case .history:
      return self.productQueries.count
    case .result:
      return self.products.count
    }
  }
  
  func cellForRow(at indexPath: IndexPath) -> ProductQuery {
    return self.productQueries[indexPath.row]
  }
  
  func cellForRow(at indexPath: IndexPath) -> Product {
    return self.products[indexPath.row]
  }
  
  func didTapCancelButton() {
    self.actions.pop()
  }
  
  func didTapKeywordDeleteButton(at indexPath: IndexPath) {
    let queryID = self.productQueries[indexPath.row].uuidString
    self.recentProductQueriesUseCase
      .deleteQuery(uuidString: queryID)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] completion in
        guard case .failure(let error) = completion else { return }
        self?.historyError = error
      } receiveValue: { [weak self] in
        self?.productQueries.remove(at: indexPath.row)
        self?.historyDeleteRowsSubject.send(indexPath)
      }
      .store(in: &self.subscriptions)
  }
  
  func didSelectRow(at indexPath: IndexPath, viewModelType: SearchViewModelType) {
    switch viewModelType {
    case .history: break
    case .result: break
    }
  }
  
  func textFieldShouldReturn(keyword: String) {
    self.recentProductQueriesUseCase
      .saveQuery(keyword: keyword)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] completion in
        guard case .failure(let error) = completion else { return }
        self?.historyError = error
      } receiveValue: { [weak self] productQuery in
        self?.productQueries.append(productQuery)
        self?.historyReloadDataSubject.send()
//        self?.actions.showProduct(keyword)
      }
      .store(in: &self.subscriptions)
  }
}
