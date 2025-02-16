//
//  ProductViewModel.swift
//  FreshNote
//
//  Created by SeokHyun on 11/14/24.
//

import Combine
import Foundation

struct ProductViewModelActions {
  typealias AnimateCategoryHandler = () -> Void
  typealias PassCategoryHandler = (String) -> Void
  
  let pop: (Product?) -> Void
  let showPhotoBottomSheet: (Data?) -> Void
  let showCategoryBottomSheet: (@escaping AnimateCategoryHandler,
                                @escaping PassCategoryHandler) -> Void
  /// 앨범에서 이미지를 가져오거나, 사진을 찍어서 이미지를 가져올 때 image의 Data를 방출하는 Publisher입니다.
  let imageDataPublisher: AnyPublisher<Data, Never>
  let deleteImagePublisher: AnyPublisher<Void, Never>
}

protocol ProductViewModel: ProductViewModelInput & ProductViewModelOutput { }

protocol ProductViewModelInput {
  func viewDidLoad()
  func didTapBackButton()
  func didTapSaveButton(name: String, expiration: String, imageData: Data?, category: String, memo: String?)
  func didTapImageView(imageData: Data?)
  func didTapCategoryTextField()
  func expirationTextFieldShouldEndEditing(_ text: String?)
  func didChangeExpirationTextField(_ text: String)
}

protocol ProductViewModelOutput {
  var categoryToggleAnimationPublisher: AnyPublisher<Void, Never> { get }
  var imageDataPublisher: AnyPublisher<Data?, Never> { get }
  var categoryPublisher: AnyPublisher<String, Never> { get }
  var expirationPublisher: AnyPublisher<ExpirationOutputState, Never> { get }
  var errorPublisher: AnyPublisher<Error?, Never> { get }
  var expirationTextPublisher: AnyPublisher<String, Never> { get }
  var isDefaultImage: Bool { get }
  var setupProductPublisher: AnyPublisher<Product, Never> { get }
  var isChangedImageIfNotDefaultImage: Bool { get }
}

enum ExpirationOutputState {
  case invalidDate(text: String) // 유효성 검사 실패
  case inCompleteDate(text: String) // 완전히 기입하지 않은 상태
  case completeDate
  case writing
}

enum ProductViewModelMode {
  case create
  case edit(DocumentID)
}

final class DefaultProductViewModel: ProductViewModel {
  private enum Constants {
    static var expirationValidTextCount: Int { 8 }
  }
  
  // MARK: - Properties
  private let actions: ProductViewModelActions
  
  private let mode: ProductViewModelMode
  
  private var subscriptions = Set<AnyCancellable>()
  
  /// 이전 text 길이를 저장해서 delete 감지할 때 사용하는 변수입니다.
  private var previousExpirationTextLength = 0

  private let saveProductUseCase: any SaveProductUseCase
  private let updateProductUseCase: any UpdateProductUseCase
  private let fetchProductUseCase: any FetchProductUseCase
  
  private var fetchedProduct: Product?
  
  // MARK: - Output
  var categoryToggleAnimationPublisher: AnyPublisher<Void, Never> {
    self.categoryToggleAnimationSubject.eraseToAnyPublisher()
  }
  var imageDataPublisher: AnyPublisher<Data?, Never> { self.imageDataSubject.eraseToAnyPublisher() }
  var categoryPublisher: AnyPublisher<String, Never> { self.categorySubject.eraseToAnyPublisher() }
  var expirationPublisher: AnyPublisher<ExpirationOutputState, Never> { self.expirationSubject.eraseToAnyPublisher() }
  var expirationTextPublisher: AnyPublisher<String, Never> { $expirationFormattedText.eraseToAnyPublisher() }
  var errorPublisher: AnyPublisher<(any Error)?, Never> { self.$error.eraseToAnyPublisher() }
  var setupProductPublisher: AnyPublisher<Product, Never> { self.setupProductSubejct.eraseToAnyPublisher() }
  
  private let categoryToggleAnimationSubject: PassthroughSubject<Void, Never> = .init()
  private let imageDataSubject: PassthroughSubject<Data?, Never> = .init()
  private let categorySubject: PassthroughSubject<String, Never> = .init()
  private let expirationSubject: PassthroughSubject<ExpirationOutputState, Never> = .init()
  private let setupProductSubejct: PassthroughSubject<Product, Never> = .init()
  
  @Published private var expirationFormattedText = ""
  @Published private var error: (any Error)?
  
  /// 기본 이미지인지 사용자가 정의한 이미지인지 판별하는 변수입니다.
  var isDefaultImage: Bool = true
  
  /// 이미지가 변경되었는지 판별하는 변수입니다.
  ///
  /// true인 경우:
    /// - 사용자가 기존(default or custom)이미지에서 다른 이미지로 변경한 경우
  ///
  /// false인 경우:
    /// - default 이미지인 경우
    /// - 커스텀 이미지 상태에서 이미지를 삭제하는 경우
  lazy var isChangedImageIfNotDefaultImage: Bool = false
  
  // MARK: - LifeCycle
  init(
    saveProductUseCase: any SaveProductUseCase,
    updateProductUseCase: any UpdateProductUseCase,
    fetchProductUseCase: any FetchProductUseCase,
    actions: ProductViewModelActions,
    mode: ProductViewModelMode
  ) {
    self.saveProductUseCase = saveProductUseCase
    self.updateProductUseCase = updateProductUseCase
    self.fetchProductUseCase = fetchProductUseCase
    self.actions = actions
    self.mode = mode
    
    self.bind()
  }
  
  deinit {
    print("DEBUG: \(Self.self) deinit")
  }
  
  // MARK: - Input
  func viewDidLoad() {
    switch self.mode {
    case .create: break
    case .edit(let productID):
      self.fetchProductUseCase
        .fetchProduct(productID: productID)
        .retry(3)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
          guard case .failure(let error) = completion else { return }
          self?.error = error
        } receiveValue: { [weak self] product in
          guard let self else { return }
          self.fetchedProduct = product
          self.isDefaultImage = product.imageURL == nil
          self.setupProductSubejct.send(product)
          self.expirationSubject.send(.completeDate)
        }
        .store(in: &self.subscriptions)
    }
  }
  
  func didTapBackButton() {
    self.actions.pop(nil)
  }
  
  func didTapSaveButton(name: String, expiration: String, imageData: Data?, category: String, memo: String?) {
    let formatManager = DateFormatManager()
    guard let date = formatManager.date(from: expiration) else { return }
    
    switch self.mode {
    case .create:
      let requestValue = SaveProductUseCaseRequestValue(
        name: name,
        expirationDate: date,
        category: category,
        memo: memo,
        imageData: imageData,
        isPinned: false
      )
      
      self.saveProductUseCase
        .execute(requestValue: requestValue)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
          guard case .failure(let error) = completion else { return }
          self?.error = error
        } receiveValue: { [weak self] product in
          guard let self else { return }
          self.actions.pop(nil)
        }
        .store(in: &self.subscriptions)
    case .edit(_):
      guard let fetchedProduct = self.fetchedProduct else { return }
      
      let updatedProductExcludedImageURL = Product(
        did: fetchedProduct.did,
        name: name,
        expirationDate: date,
        category: category,
        memo: memo,
        imageURL: fetchedProduct.imageURL,
        isPinned: fetchedProduct.isPinned,
        creationDate: fetchedProduct.creationDate
      )
      self.updateProductUseCase.setImageDeletionValue(self.isDefaultImage)
      
      self.updateProductUseCase
        .execute(
          product: updatedProductExcludedImageURL,
          newImageData: imageData
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
          guard case .failure(let error) = completion else { return }
          self?.error = error
        } receiveValue: { [weak self] product in
          guard let self else { return }
          
          self.actions.pop(product)
        }
        .store(in: &self.subscriptions)
    }
  }
  
  func didTapImageView(imageData: Data?) {
    if !self.isDefaultImage {
      self.actions.showPhotoBottomSheet(imageData)
    } else {
      self.actions.showPhotoBottomSheet(nil)
    }
  }
  
  func didTapCategoryTextField() {
    let animateCategoryHandler: ProductViewModelActions.AnimateCategoryHandler = { [weak self] in
      self?.categoryToggleAnimationSubject.send()
    }
    let passCategoryHandler: ProductViewModelActions.PassCategoryHandler = { [weak self] category in
      self?.categorySubject.send(category)
    }
    
    self.actions.showCategoryBottomSheet(animateCategoryHandler, passCategoryHandler)
  }
  
  func expirationTextFieldShouldEndEditing(_ text: String?) {
    guard let text = text, text.count >= Constants.expirationValidTextCount else {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy"
      dateFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
      dateFormatter.locale = Locale(identifier: "ko_KR")
      let yearString = dateFormatter.string(from: Date())
      
      let exampleDate = String("ex)" + yearString.suffix(2) + ".01.01")
      self.expirationSubject.send(.inCompleteDate(text: "유통기한이 완전히 입력되지 않았습니다. " + exampleDate))
      return
    }
  }
  
  func didChangeExpirationTextField(_ text: String) {
    let isDeleting = text.count < self.previousExpirationTextLength
    
    // 삭제 시에는 포맷팅 없이 현재 text 사용
    if isDeleting {
      self.expirationFormattedText = text
      self.previousExpirationTextLength = text.count
      self.expirationSubject.send(.writing)
      return
    }
    
    // 입력된 텍스트에서 마지막 문자가 숫자인 경우에만 포맷팅 진행
    if let lastChar = text.last, lastChar.isNumber {
      let numbers = text.filter { $0.isNumber }
      var formatted = ""
      
      if numbers.count >= 2 {
        let year = String(numbers.prefix(2))
        formatted = year + "."
        
        if numbers.count >= 4 {
          let month = String(numbers.dropFirst(2).prefix(2))
          formatted += month + "."
          
          if numbers.count >= 5 { // day
            let day = String(numbers.dropFirst(4).prefix(2))
            formatted += day
          }
        } else {
          formatted += String(numbers.dropFirst(2))
        }
      } else {
        formatted = String(numbers)
      }
      
      self.expirationFormattedText = formatted
      self.previousExpirationTextLength = formatted.count
      
      if self.expirationFormattedText.count < Constants.expirationValidTextCount {
        self.expirationSubject.send(.writing)
      } else {
        self.validateDate(with: formatted)
      }
    }
  }
  
  // MARK: - Bind
  private func bind() {
    self.actions.imageDataPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] imageData in
        self?.isDefaultImage = false
        self?.isChangedImageIfNotDefaultImage = true
        self?.imageDataSubject.send(imageData)
      }
      .store(in: &self.subscriptions)
    
    self.actions.deleteImagePublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in
        self?.isDefaultImage = true
        self?.isChangedImageIfNotDefaultImage = false
        self?.imageDataSubject.send(nil)
      }
      .store(in: &self.subscriptions)
  }
  
  // MARK: - Private Helpers
  private func validateDate(with dateString: String) {
    let associatedSring = "잘못된 유통기한입니다."
    
    // 1. 형식 검사 (YY.MM.DD)
    let components = dateString.components(separatedBy: ".")
    let yearStr = components[0]
    let monthStr = components[1]
    let dayStr = components[2]
    
    guard components.count == 3,
          let year = Int("20" + yearStr),
          let month = Int(monthStr),
          let day = Int(dayStr)
    else {
      self.expirationSubject.send(.invalidDate(text: associatedSring))
      return
    }
    
    // 월 검사 (1-12)
    guard (1...12).contains(month)
    else {
      self.expirationSubject.send(.invalidDate(text: associatedSring))
      return
    }
    
    // 해당 월의 마지막 날짜 계산
    var dateComponents = DateComponents()
    dateComponents.year = year
    dateComponents.month = month
    dateComponents.day = 1
    
    let calendar = Calendar.current
    guard let date = calendar.date(from: dateComponents),
          let range = calendar.range(of: .day, in: .month, for: date) else {
      self.expirationSubject.send(.invalidDate(text: associatedSring))
      return
    }
    
    // 일자 검사
    let isValid = (1...range.count).contains(day)
    if isValid {
      self.expirationSubject.send(.completeDate)
    } else {
      self.expirationSubject.send(.invalidDate(text: associatedSring))
    }
  }
}
