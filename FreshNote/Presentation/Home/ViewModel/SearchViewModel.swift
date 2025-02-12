//
//  SearchViewModel.swift
//  FreshNote
//
//  Created by SeokHyun on 11/1/24.
//

import Combine
import Foundation

protocol SearchViewModel: SearchViewModelInput, SearchViewModelOutput,
                          SearchHistoryViewModel, SearchResultViewModel { }

typealias SearchHistoryViewModel = SearchHistoryViewModelInput & SearchHistoryViewModelOutput

typealias SearchResultViewModel = SearchResultViewModelInput & SearchResultViewModelOutput

protocol SearchHistoryViewModelInput {
  func didTapAllDeletionButton()
  func cellForRow(at indexPath: IndexPath) -> ProductQuery
  func didTapKeywordDeleteButton(at indexPath: IndexPath)
  func historyNumberOfRowsInSection() -> Int
  func historyDidSelectRow(at indexPath: IndexPath)
  func isDataSourceEmpty() -> Bool
}

protocol SearchHistoryViewModelOutput {
  var historyDeleteRowsPublisher: AnyPublisher<IndexPath, Never> { get }
  var historyReloadDataPublisher: AnyPublisher<Void, Never> { get }
  var historyErrorPublisher: AnyPublisher<(any Error)?, Never> { get }
}

protocol SearchResultViewModelInput {
  func cellForRow(at indexPath: IndexPath) -> Product
  func resultNumberOfRowsInSection() -> Int
  func resultDidSelectRow(at indexPath: IndexPath)
  func didTapPin(at indexPath: IndexPath)
}

protocol SearchResultViewModelOutput {
  var resultErrorPublisher: AnyPublisher<(any Error)?, Never> { get }
  var resultReloadDataPublisher: AnyPublisher<Void, Never> { get }
  var updatePinPublisher: AnyPublisher<(IndexPath, Bool), Never> { get }
}

protocol SearchViewModelInput {
  func viewDidLoad()
  func didTapCancelButton()
  func textFieldShouldReturn(keyword: String)
}

protocol SearchViewModelOutput {
  var updateTextPubilsher: AnyPublisher<String, Never> { get }
}

struct SearchViewModelActions {
  let pop: () -> Void
  let showProduct: (DocumentID) -> Void
  let updateProductPublisher: AnyPublisher<Product?, Never>
}

final class DefaultSearchViewModel: SearchViewModel {
  // MARK: - Properties
  private var productQueries: [ProductQuery] = []
  private var products: [Product] = []
  private let actions: SearchViewModelActions
  private var subscriptions = Set<AnyCancellable>()
  private let recentProductQueriesUseCase: any RecentProductQueriesUseCase
  private let fetchProductUseCase: any FetchProductUseCase
  private let updateProductUseCase: any UpdateProductUseCase
  
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
  var updatePinPublisher: AnyPublisher<(IndexPath, Bool), Never> { self.updatePinSubject.eraseToAnyPublisher() }
  @Published private var resultError: (any Error)?
  private let resultReloadDataSubject: PassthroughSubject<Void, Never> = .init()
  private let updatePinSubject: PassthroughSubject<(IndexPath, Bool), Never> = .init()
  
  var updateTextPubilsher: AnyPublisher<String, Never> { self.updateTextSubject.eraseToAnyPublisher() }
  private let updateTextSubject: PassthroughSubject<String, Never> = .init()
  
  private var updatingProductIndexPath: IndexPath?
  
  // MARK: - LifeCycle
  init(
    actions: SearchViewModelActions,
    recentProductQueriesUseCase: any RecentProductQueriesUseCase,
    fetchProductUseCase: any FetchProductUseCase,
    updateProductUseCase: any UpdateProductUseCase
  ) {
    self.actions = actions
    self.recentProductQueriesUseCase = recentProductQueriesUseCase
    self.fetchProductUseCase = fetchProductUseCase
    self.updateProductUseCase = updateProductUseCase
    
    self.bind()
  }
  
  deinit {
    print("DEBUG: \(Self.self) deinit")
  }
  
  // MARK: - Bind
  private func bind() {
    self.actions.updateProductPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] updatedProduct in
        guard
          let updatedProduct = updatedProduct,
          let updatingProductIndexPath = self?.updatingProductIndexPath else {
          self?.updatingProductIndexPath = nil
          return
        }
        
        self?.updatingProductIndexPath = nil
        self?.products[updatingProductIndexPath.row] = updatedProduct
        self?.resultReloadDataSubject.send()
      }
      .store(in: &self.subscriptions)
  }
  
  // MARK: - Input
  func isDataSourceEmpty() -> Bool {
    self.productQueries.isEmpty
  }
  
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
  
  func didTapPin(at indexPath: IndexPath) {
    let product = self.products[indexPath.row]
    let updatedPinState = product.isPinned ? false : true
    let updatingProduct = self.makeUpdatingProduct(product: product, updatedPinState: updatedPinState)
    
    self.updateProductUseCase.execute(product: updatingProduct, newImageData: nil)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] completion in
        guard case .failure(let error) = completion else { return }
        self?.resultError = error
      } receiveValue: { [weak self] updatedProduct in
        self?.products[indexPath.row] = updatedProduct
        self?.updatePinSubject.send((indexPath, updatedPinState))
      }
      .store(in: &self.subscriptions)
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
      }
      .store(in: &self.subscriptions)
    
    self.fetchProductUseCase
      .fetchProduct(keyword: keyword)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] completion in
        guard case .failure(let error) = completion else { return }
        self?.resultError = error
      } receiveValue: { [weak self] products in
        self?.products = products
        self?.resultReloadDataSubject.send()
      }
      .store(in: &self.subscriptions)
  }
  
  func didTapAllDeletionButton() {
    self.recentProductQueriesUseCase
      .deleteQueries()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] completion in
        guard case .failure(let error) = completion else { return }
        self?.historyError = error
      } receiveValue: { [weak self] _ in
        self?.productQueries.removeAll()
        self?.historyReloadDataSubject.send()
      }
      .store(in: &self.subscriptions)
  }
  
  func historyNumberOfRowsInSection() -> Int {
    return self.productQueries.count
  }
  
  func historyDidSelectRow(at indexPath: IndexPath) {
    let query = self.productQueries[indexPath.row].keyword
    self.updateTextSubject.send(query)
    
    self.fetchProductUseCase
      .fetchProduct(keyword: query)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] completion in
        guard case .failure(let error) = completion else { return }
        self?.resultError = error
      } receiveValue: { [weak self] products in
        self?.products = products
        self?.resultReloadDataSubject.send()
      }
      .store(in: &self.subscriptions)
  }
  
  func resultNumberOfRowsInSection() -> Int {
    return self.products.count
  }
  
  func resultDidSelectRow(at indexPath: IndexPath) {
    let productID = self.products[indexPath.row].did
    self.updatingProductIndexPath = indexPath
    self.actions.showProduct(productID)
  }
  
  // MARK: - Private
  private func makeUpdatingProduct(product: Product, updatedPinState: Bool) -> Product {
    return Product(
      did: product.did,
      name: product.name,
      expirationDate: product.expirationDate,
      category: product.category,
      memo: product.memo,
      imageURL: product.imageURL,
      isPinned: updatedPinState,
      creationDate: product.creationDate
    )
  }
}
