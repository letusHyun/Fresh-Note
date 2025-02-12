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
  func didTapPin(at indexPath: IndexPath)
  func isDataSourceEmpty() -> Bool
}

protocol PinViewModelOutput {
  var errorPublisher: AnyPublisher<(any Error)?, Never> { get }
  var reloadDataPublisher: AnyPublisher<Void, Never> { get }
  var deleteRowsPublisher: AnyPublisher<IndexPath, Never> { get }
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
  var deleteRowsPublisher: AnyPublisher<IndexPath, Never> { self.deleteRowsSubject.eraseToAnyPublisher() }
  
  @Published private var error: (any Error)?
  private let reloadDataSubject: PassthroughSubject<Void, Never> = .init()
  private let deleteRowsSubject: PassthroughSubject<IndexPath, Never> = .init()
  
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
    self.fetchProductUseCase.fetchPinnedProducts()
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
  
  func didTapPin(at indexPath: IndexPath) {
    let product = self.dataSource[indexPath.row]
    let updatedPinState = product.isPinned ? false : true
    let updatingProduct = self.makeUpdatingProduct(product: product, updatedPinState: updatedPinState)
    
    self.updateProductUseCase.execute(
      product: updatingProduct, newImageData: nil)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] completion in
        guard case .failure(let error) = completion else { return }
        self?.error = error
      } receiveValue: { [weak self] _ in
        self?.dataSource.remove(at: indexPath.row)
        self?.deleteRowsSubject.send(indexPath)
      }
      .store(in: &self.subscriptions)
  }
  
  func isDataSourceEmpty() -> Bool {
    self.dataSource.isEmpty
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
