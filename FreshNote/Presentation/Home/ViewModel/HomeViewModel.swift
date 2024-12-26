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
  let showProductPage: (Product?) -> Void
  let productPublisher: AnyPublisher<Product?, Never>
}

protocol HomeViewModelInput {
  func viewDidLoad()
  func numberOfItemsInSection() -> Int
  func cellForItemAt(indexPath: IndexPath) -> Product
  func trailingSwipeActionsConfigurationForRowAt(indexPath: IndexPath, handler: @escaping (Bool) -> Void)
  func didTapNotificationButton()
  func didTapSearchButton()
  func didTapAddProductButton()
  func didSelectRow(at indexPath: IndexPath)
}

protocol HomeViewModelOutput {
  var reloadDataPublisher: AnyPublisher<Void, Never> { get }
  var deleteRowsPublisher: AnyPublisher<([IndexPath], (Bool) -> Void), Never> { get }
  var errorPublisher: AnyPublisher<(any Error)?, Never> { get }
  var reloadRowsPublisher: AnyPublisher<[IndexPath], Never> { get }
}

protocol HomeViewModel: HomeViewModelInput, HomeViewModelOutput {}

final class DefaultHomeViewModel: HomeViewModel {
  typealias SwipeCompletion = (Bool) -> Void
  
  // MARK: - Properties
  private let actions: HomeViewModelActions
  private var items = [Product]()
  private var subscriptions = Set<AnyCancellable>()
  private let fetchProductUseCase: any FetchProductUseCase
  private let deleteProductUseCase: any DeleteProductUseCase
  
  /// 제품의 update 유무 및 업데이트된 indexPath를 저장하는 변수입니다.
  private var updatedIndexPath: IndexPath?
  
  // MARK: - Output
  private var reloadDataSubject: PassthroughSubject<Void, Never> = PassthroughSubject()
  private var deleteRowsSubject: PassthroughSubject<([IndexPath], SwipeCompletion), Never> = PassthroughSubject()
  private var reloadRowsSubject: PassthroughSubject<[IndexPath], Never> = PassthroughSubject()
  
  var reloadDataPublisher: AnyPublisher<Void, Never> { self.reloadDataSubject.eraseToAnyPublisher() }
  var deleteRowsPublisher: AnyPublisher<([IndexPath], SwipeCompletion), Never>
  { self.deleteRowsSubject.eraseToAnyPublisher() }
  var errorPublisher: AnyPublisher<(any Error)?, Never> { self.$error.eraseToAnyPublisher() }
  var reloadRowsPublisher: AnyPublisher<[IndexPath], Never> { self.reloadRowsSubject.eraseToAnyPublisher() }
  
  @Published private var error: (any Error)?
  
  // MARK: - LifeCycle
  init(actions: HomeViewModelActions,
       fetchProductUseCase: any FetchProductUseCase,
       deleteProductUseCase: any DeleteProductUseCase
  ) {
    self.actions = actions
    self.fetchProductUseCase = fetchProductUseCase
    self.deleteProductUseCase = deleteProductUseCase
    
    self.bind()
  }
  
  // MARK: - Input
  func viewDidLoad() {
    return self.fetchProductUseCase.fetchProducts()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] completion in
        guard case .failure(let error) = completion else { return }
        self?.error = error
      } receiveValue: { [weak self] products in
        for product in products {
          self?.items.append(product)
        }
        self?.reloadDataSubject.send()
      }
      .store(in: &self.subscriptions)
  }
  
  func numberOfItemsInSection() -> Int {
    self.items.count
  }
  
  func cellForItemAt(indexPath: IndexPath) -> Product {
    self.items[indexPath.row]
  }
  
  func trailingSwipeActionsConfigurationForRowAt(indexPath: IndexPath, handler: @escaping SwipeCompletion) {
    let item = items[indexPath.row]
  
    self.deleteProductUseCase
      .execute(did: item.did, imageURL: item.imageURL)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] completion in
        guard case .failure(let error) = completion else { return }
        self?.error = error
      } receiveValue: { _ in
        self.items.remove(at: indexPath.row)
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
    let product = self.items[indexPath.row]
    self.updatedIndexPath = indexPath
    self.actions.showProductPage(product)
  }
  
  // MARK: - Private Helpers
  private func bind() {
    self.actions.productPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] product in
        guard let product = product else {
          // 뒤로가기
          self?.updatedIndexPath = nil
          return
        }
        // 저장버튼
        self?.updateItems(product: product)
      }
      .store(in: &self.subscriptions)
  }
  
  private func updateItems(product: Product) {
    if let updatedIndexPath = self.updatedIndexPath { // edit
      self.items[updatedIndexPath.row] = product
      self.reloadRowsSubject.send([updatedIndexPath])
      self.updatedIndexPath = nil
    } else { // create
      self.items.append(product)
      self.reloadDataSubject.send()
    }
  }
}
