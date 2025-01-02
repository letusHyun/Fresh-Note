//
//  PinViewModel.swift
//  FreshNote
//
//  Created by SeokHyun on 12/31/24.
//

import Combine
import Foundation

struct PinViewModelActions {
  let showProduct: (DocumentID) -> Void
}

protocol PinViewModelInput {
  func viewDidLoad()
  func viewWillAppear()
  func numberOfRowsInSection() -> Int
  func cellForRow(at indexPath: IndexPath) -> Product
  func didSelectRow(at indexPath: IndexPath)
}

protocol PinViewModelOutput {
  var errorPublisher: AnyPublisher<(any Error)?, Never> { get }
  var reloadDataPublisher: AnyPublisher<Void, Never> { get }
}

protocol PinViewModel: PinViewModelInput, PinViewModelOutput { }

final class DefaultPinViewModel: PinViewModel {
  // MARK: - Properties
  private let fetchProductUseCase: any FetchProductUseCase
  private let updateProductUseCase: any UpdateProductUseCase
  private var subscriptions: Set<AnyCancellable> = []
  private var dataSource = [Product]()
  private let actions: PinViewModelActions
  
  // MARK: - Output
  var errorPublisher: AnyPublisher<(any Error)?, Never> { self.$error.eraseToAnyPublisher() }
  var reloadDataPublisher: AnyPublisher<Void, Never> { self.reloadDataSubject.eraseToAnyPublisher() }
  
  @Published private var error: (any Error)?
  private let reloadDataSubject: PassthroughSubject<Void, Never> = .init()
  
  // MARK: - LifeCycle
  init(
    actions: PinViewModelActions,
    fetchProductUseCase: any FetchProductUseCase,
    updateProductUseCase: any UpdateProductUseCase
  ) {
    self.actions = actions
    self.fetchProductUseCase = fetchProductUseCase
    self.updateProductUseCase = updateProductUseCase
  }
  
  // MARK: - Input
  func viewDidLoad() {
    
  }
  
  func viewWillAppear() {
    self.fetchProductUseCase.fetchProducts()
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
  
  func numberOfRowsInSection() -> Int {
    self.dataSource.count
  }
  
  func cellForRow(at indexPath: IndexPath) -> Product {
    return self.dataSource[indexPath.row]
  }
  
  func didSelectRow(at indexPath: IndexPath) {
    let selectedProduct = self.dataSource[indexPath.row]
    self.actions.showProduct(selectedProduct.did)
  }
  
  // MARK: - Private
}
