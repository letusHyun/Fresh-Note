//
//  CategoryDetailViewModel.swift
//  FreshNote
//
//  Created by SeokHyun on 1/7/25.
//

import Combine
import Foundation

struct CategoryDetailViewModelActions {
  let pop: () -> Void
  let showProduct: (DocumentID) -> Void
}

protocol CategoryDetailViewModelInput {
  func viewDidLoad()
  func numberOfRowsInSection() -> Int
  func cellForItem(at indexPath: IndexPath) -> Product
  func didSelectRow(at indexPath: IndexPath)
  func viewWillAppear()
  func didTapPin(at indexPath: IndexPath)
  func isDataSourceEmpty() -> Bool
}

protocol CategoryDetailViewModelOutput {
  var reloadDataPublisher: AnyPublisher<Void, Never> { get }
  var errorPublisher: AnyPublisher<(any Error)?, Never> { get }
  var configureTitlePublisher: AnyPublisher<String, Never> { get }
  var updatePinPublisher: AnyPublisher<(IndexPath, Bool), Never> { get }
}

protocol CategoryDetailViewModel: CategoryDetailViewModelInput & CategoryDetailViewModelOutput { }

final class DefaultCategoryDetailViewModel: CategoryDetailViewModel {
  // MARK: - Properties
  private let actions: CategoryDetailViewModelActions
  private let fetchProductUseCase: any FetchProductUseCase
  private let updateProductUseCase: any UpdateProductUseCase
  private var dataSource: [Product] = []
  private let category: ProductCategory
  private var subscriptions: Set<AnyCancellable> = []
  
  // MARK: - Output
  var reloadDataPublisher: AnyPublisher<Void, Never> { self.reloadDateSubject.eraseToAnyPublisher() }
  var errorPublisher: AnyPublisher<(any Error)?, Never> { self.$error.eraseToAnyPublisher() }
  var configureTitlePublisher: AnyPublisher<String, Never> { self.configureTitleSubject.eraseToAnyPublisher() }
  var updatePinPublisher: AnyPublisher<(IndexPath, Bool), Never> { self.updatePinSubject.eraseToAnyPublisher() }
  
  private let reloadDateSubject: PassthroughSubject<Void, Never> = .init()
  @Published private var error: (any Error)?
  private let configureTitleSubject: PassthroughSubject<String, Never> = .init()
  private let updatePinSubject: PassthroughSubject<(IndexPath, Bool), Never> = .init()
  
  // MARK: - LifeCycle
  init(
    actions: CategoryDetailViewModelActions,
    category: ProductCategory,
    fetchProductUseCase: any FetchProductUseCase,
    updateProductUseCase: any UpdateProductUseCase
  ) {
    self.actions = actions
    self.category = category
    self.fetchProductUseCase = fetchProductUseCase
    self.updateProductUseCase = updateProductUseCase
  }
  
  
  // MARK: - Input
  func isDataSourceEmpty() -> Bool {
    self.dataSource.isEmpty
  }
  
  func viewDidLoad() {
    self.configureTitleSubject.send(self.category.rawValue)
  }
  
  func viewWillAppear() {
    self.fetchProductUseCase
      .fetchProduct(category: self.category)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] completion in
        guard case .failure(let error) = completion else { return }
        self?.error = error
      } receiveValue: { [weak self] products in
        self?.dataSource = products
        self?.reloadDateSubject.send()
      }
      .store(in: &self.subscriptions)
  }
  
  func numberOfRowsInSection() -> Int {
    self.dataSource.count
  }
  
  func cellForItem(at indexPath: IndexPath) -> Product {
    return self.dataSource[indexPath.row]
  }
  
  func didSelectRow(at indexPath: IndexPath) {
    let productID = self.dataSource[indexPath.row].did
    self.actions.showProduct(productID)
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
