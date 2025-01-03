//
//  HomeViewModel.swift
//  FreshNote
//
//  Created by SeokHyun on 10/28/24.
//

import Combine
import Foundation

struct HomeViewModelActions {
  let showNotificationPage: () -> Void
  let showSearchPage: () -> Void
  let showProductPage: (DocumentID?) -> Void
}

protocol HomeViewModelInput {
  func viewDidLoad()
  func viewWillAppear()
  func numberOfItemsInSection() -> Int
  func cellForItemAt(indexPath: IndexPath) -> Product
  func trailingSwipeActionsConfigurationForRowAt(indexPath: IndexPath, handler: @escaping (Bool) -> Void)
  func didTapNotificationButton()
  func didTapSearchButton()
  func didTapAddProductButton()
  func didSelectRow(at indexPath: IndexPath)
  func didTapPin(at indexPath: IndexPath)
}

protocol HomeViewModelOutput {
  var reloadDataPublisher: AnyPublisher<Void, Never> { get }
  var deleteRowsPublisher: AnyPublisher<([IndexPath], (Bool) -> Void), Never> { get }
  var errorPublisher: AnyPublisher<(any Error)?, Never> { get }
  var reloadRowsPublisher: AnyPublisher<[IndexPath], Never> { get }
  var updatePinPublisher: AnyPublisher<(IndexPath, Bool), Never> { get }
}

protocol HomeViewModel: HomeViewModelInput, HomeViewModelOutput {}

final class DefaultHomeViewModel: HomeViewModel {
  typealias SwipeCompletion = (Bool) -> Void
  
  // MARK: - Properties
  private let actions: HomeViewModelActions
  private var items = [Product]()
  private var dataSource: [Product] = []
  private var subscriptions = Set<AnyCancellable>()
  
  private let fetchProductUseCase: any FetchProductUseCase
  private let deleteProductUseCase: any DeleteProductUseCase
  private let updateProductUseCase: any UpdateProductUseCase
  
  // MARK: - Output
  private var reloadDataSubject: PassthroughSubject<Void, Never> = PassthroughSubject()
  private var deleteRowsSubject: PassthroughSubject<([IndexPath], SwipeCompletion), Never> = PassthroughSubject()
  private var reloadRowsSubject: PassthroughSubject<[IndexPath], Never> = PassthroughSubject()
  private var updatePinSubject: PassthroughSubject<(IndexPath, Bool), Never> = PassthroughSubject()
  
  var updatePinPublisher: AnyPublisher<(IndexPath, Bool), Never> { self.updatePinSubject.eraseToAnyPublisher() }
  var reloadDataPublisher: AnyPublisher<Void, Never> { self.reloadDataSubject.eraseToAnyPublisher() }
  var deleteRowsPublisher: AnyPublisher<([IndexPath], SwipeCompletion), Never>
  { self.deleteRowsSubject.eraseToAnyPublisher() }
  var errorPublisher: AnyPublisher<(any Error)?, Never> { self.$error.eraseToAnyPublisher() }
  var reloadRowsPublisher: AnyPublisher<[IndexPath], Never> { self.reloadRowsSubject.eraseToAnyPublisher() }
  
  @Published private var error: (any Error)?
  
  // MARK: - LifeCycle
  init(actions: HomeViewModelActions,
       fetchProductUseCase: any FetchProductUseCase,
       deleteProductUseCase: any DeleteProductUseCase,
       updateProductUseCase: any UpdateProductUseCase
  ) {
    self.actions = actions
    self.fetchProductUseCase = fetchProductUseCase
    self.deleteProductUseCase = deleteProductUseCase
    self.updateProductUseCase = updateProductUseCase
  }
  
  // MARK: - Input
  func viewDidLoad() {
    
  }
  
  func viewWillAppear() {
    return self.fetchProductUseCase.fetchProducts()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] completion in
        guard case .failure(let error) = completion else { return }
        self?.error = error
      } receiveValue: { [weak self] products in
        self?.dataSource = products
        self?.reloadDataSubject.send()
      }
      .store(in: &self.subscriptions)
  }
  
  func numberOfItemsInSection() -> Int {
    self.dataSource.count
  }
  
  func cellForItemAt(indexPath: IndexPath) -> Product {
    self.dataSource[indexPath.row]
  }
  
  func trailingSwipeActionsConfigurationForRowAt(indexPath: IndexPath, handler: @escaping SwipeCompletion) {
    let item = dataSource[indexPath.row]
  
    self.deleteProductUseCase
      .execute(did: item.did, imageURL: item.imageURL)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] completion in
        guard case .failure(let error) = completion else { return }
        self?.error = error
      } receiveValue: { _ in
        self.dataSource.remove(at: indexPath.row)
        self.deleteRowsSubject.send(([indexPath], handler))
      }
      .store(in: &self.subscriptions)
  }
  
  func didTapNotificationButton() {
    self.actions.showNotificationPage()
  }
  
  func didTapSearchButton() {
    self.actions.showSearchPage()
  }
  
  func didTapAddProductButton() {
    self.actions.showProductPage(nil)
  }
  
  func didSelectRow(at indexPath: IndexPath) {
    let product = self.dataSource[indexPath.row]
    self.actions.showProductPage(product.did)
  }
  
  func didTapPin(at indexPath: IndexPath) {
    let product = self.dataSource[indexPath.row]
    let updatedPinState = product.isPinned ? false : true
    let updatingProduct = self.makeUpdatingProduct(product: product, updatedPinState: updatedPinState)
    
    self.updateProductUseCase.execute(product: updatingProduct, newImageData: nil)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] completion in
        guard case .failure(let error) = completion else { return }
        self?.error = error
      } receiveValue: { [weak self] updatedProduct in
        self?.dataSource[indexPath.row] = updatedProduct
        self?.updatePinSubject.send((indexPath, updatedPinState))
      }
      .store(in: &self.subscriptions)
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
