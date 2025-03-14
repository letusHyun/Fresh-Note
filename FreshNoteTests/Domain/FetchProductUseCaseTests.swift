//
//  FetchProductUseCaseTests.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import XCTest
import Combine

final class FetchProductUseCaseTests: XCTestCase {
  
  // MARK: - Properties
  
  private var productRepository: ProductRepositoryMock!
  private var sut: DefaultFetchProductUseCase!
  private var cancellables: Set<AnyCancellable>!
  
  // MARK: - Setup & Teardown
  
  override func setUp() {
    super.setUp()
    
    self.productRepository = ProductRepositoryMock()
    self.sut = DefaultFetchProductUseCase(productRepository: self.productRepository)
    self.cancellables = []
  }
  
  override func tearDown() {
    super.tearDown()
    
    self.productRepository = nil
    self.sut = nil
    self.cancellables = nil
  }
  
  // MARK: - Helper Methods
  
  private func createProduct(
    id: String,
    name: String,
    expirationDate: Date,
    creationDate: Date,
    isPinned: Bool = false
  ) -> Product {
    return Product(
      did: DocumentID(from: UUID().uuidString)!,
      name: name,
      expirationDate: expirationDate,
      category: ProductCategory.건강,
      memo: nil,
      imageURL: nil,
      isPinned: isPinned,
      creationDate: creationDate
    )
  }
  
  // MARK: - Test fetchProducts 메소드
  
  func test_fetchProducts_shouldCallRepository() {
    // Given
    let expectation = XCTestExpectation(description: "Repository is called")
    
    self.productRepository.fetchProductsResult = Just([])
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // When
    self.sut.fetchProducts(sort: .default)
      .sink(
        receiveCompletion: { _ in
          expectation.fulfill()
        },
        receiveValue: { _ in }
      )
      .store(in: &self.cancellables)
    
    // Then
    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(self.productRepository.fetchProductsCallCount, 1)
  }
  
  func test_fetchProducts_whenSortIsDefault_shouldPrioritizeNonExpiredProducts() {
    // Given
    let expectation = XCTestExpectation(description: "Products are sorted correctly")
    
    let now = Date()
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
    
    let expiredProduct = createProduct(
      id: "1",
      name: "만료된 제품",
      expirationDate: yesterday,
      creationDate: now
    )
    
    let validProduct = createProduct(
      id: "2",
      name: "유효한 제품",
      expirationDate: tomorrow,
      creationDate: now
    )
    
    self.productRepository.fetchProductsResult = Just([expiredProduct, validProduct])
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // When
    self.sut.fetchProducts(sort: .default)
      .sink(
        receiveCompletion: { _ in
          expectation.fulfill()
        },
        receiveValue: { products in
          // Then
          XCTAssertEqual(products.count, 2)
          // didString으로 비교하지 않고 name으로 비교
          XCTAssertEqual(products[0].name, "유효한 제품") // 유효한 제품이 먼저 나와야 함
          XCTAssertEqual(products[1].name, "만료된 제품") // 만료된 제품은 나중에 나와야 함
        }
      )
      .store(in: &self.cancellables)
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func test_fetchProducts_whenSortIsDefaultAndAllProductsValid_shouldSortByCreationDateDescending() {
    // Given
    let expectation = XCTestExpectation(description: "Products are sorted by creation date")
    
    let now = Date()
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
    let dayAfterTomorrow = Calendar.current.date(byAdding: .day, value: 2, to: now)!
    
    let oldestCreationDate = Calendar.current.date(byAdding: .day, value: -10, to: now)!
    let newerCreationDate = Calendar.current.date(byAdding: .day, value: -5, to: now)!
    let newestCreationDate = Calendar.current.date(byAdding: .day, value: -2, to: now)!
    
    let product1 = createProduct(
      id: "1",
      name: "오래된 생성일",
      expirationDate: tomorrow,
      creationDate: oldestCreationDate
    )
    
    let product2 = createProduct(
      id: "2",
      name: "중간 생성일",
      expirationDate: tomorrow,
      creationDate: newerCreationDate
    )
    
    let product3 = createProduct(
      id: "3",
      name: "최신 생성일",
      expirationDate: dayAfterTomorrow,
      creationDate: newestCreationDate
    )
    
    self.productRepository.fetchProductsResult = Just([product1, product2, product3])
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // When
    self.sut.fetchProducts(sort: .default)
      .sink(
        receiveCompletion: { _ in
          expectation.fulfill()
        },
        receiveValue: { products in
          // Then
          XCTAssertEqual(products.count, 3)
          // name으로 비교
          XCTAssertEqual(products[0].name, "최신 생성일") // 최신 생성일 먼저
          XCTAssertEqual(products[1].name, "중간 생성일") // 중간 생성일
          XCTAssertEqual(products[2].name, "오래된 생성일") // 오래된 생성일
        }
      )
      .store(in: &self.cancellables)
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func test_fetchProducts_whenSortIsDefaultAndAllProductsExpired_shouldSortByCreationDateDescending() {
    // Given
    let expectation = XCTestExpectation(description: "Expired products are sorted by creation date")
    
    let now = Date()
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
    let dayBeforeYesterday = Calendar.current.date(byAdding: .day, value: -2, to: now)!
    
    let oldestCreationDate = Calendar.current.date(byAdding: .day, value: -10, to: now)!
    let newerCreationDate = Calendar.current.date(byAdding: .day, value: -5, to: now)!
    let newestCreationDate = Calendar.current.date(byAdding: .day, value: -2, to: now)!
    
    let product1 = createProduct(
      id: "1",
      name: "오래된 생성일",
      expirationDate: dayBeforeYesterday,
      creationDate: oldestCreationDate
    )
    
    let product2 = createProduct(
      id: "2",
      name: "중간 생성일",
      expirationDate: yesterday,
      creationDate: newerCreationDate
    )
    
    let product3 = createProduct(
      id: "3",
      name: "최신 생성일",
      expirationDate: yesterday,
      creationDate: newestCreationDate
    )
    
    self.productRepository.fetchProductsResult = Just([product1, product2, product3])
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // When
    self.sut.fetchProducts(sort: .default)
      .sink(
        receiveCompletion: { _ in
          expectation.fulfill()
        },
        receiveValue: { products in
          // Then
          XCTAssertEqual(products.count, 3)
          // name으로 비교
          XCTAssertEqual(products[0].name, "최신 생성일") // 최신 생성일 먼저
          XCTAssertEqual(products[1].name, "중간 생성일") // 중간 생성일
          XCTAssertEqual(products[2].name, "오래된 생성일") // 오래된 생성일
        }
      )
      .store(in: &self.cancellables)
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func test_fetchProducts_whenSortIsDefaultWithMixedExpirationAndCreationDates_shouldSortCorrectly() {
    // Given
    let expectation = XCTestExpectation(description: "Mixed products are sorted correctly")
    
    let now = Date()
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
    
    let oldestCreationDate = Calendar.current.date(byAdding: .day, value: -10, to: now)!
    let newerCreationDate = Calendar.current.date(byAdding: .day, value: -5, to: now)!
    let newestCreationDate = Calendar.current.date(byAdding: .day, value: -2, to: now)!
    
    // 유효한 제품, 최신 생성일
    let product1 = createProduct(
      id: "1",
      name: "유효한 제품 (최신 생성일)",
      expirationDate: tomorrow,
      creationDate: newestCreationDate
    )
    
    // 유효한 제품, 오래된 생성일
    let product2 = createProduct(
      id: "2",
      name: "유효한 제품 (오래된 생성일)",
      expirationDate: tomorrow,
      creationDate: oldestCreationDate
    )
    
    // 만료된 제품, 최신 생성일
    let product3 = createProduct(
      id: "3",
      name: "만료된 제품 (최신 생성일)",
      expirationDate: yesterday,
      creationDate: newerCreationDate
    )
    
    // 만료된 제품, 오래된 생성일
    let product4 = createProduct(
      id: "4",
      name: "만료된 제품 (오래된 생성일)",
      expirationDate: yesterday,
      creationDate: oldestCreationDate
    )
    
    self.productRepository.fetchProductsResult = Just([product4, product3, product2, product1])
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // When
    self.sut.fetchProducts(sort: .default)
      .sink(
        receiveCompletion: { _ in
          expectation.fulfill()
        },
        receiveValue: { products in
          // Then
          XCTAssertEqual(products.count, 4)
          // name으로 비교
          // 유효한 제품들이 먼저 (생성일 내림차순)
          XCTAssertEqual(products[0].name, "유효한 제품 (최신 생성일)") // 유효한 제품 (최신 생성일)
          XCTAssertEqual(products[1].name, "유효한 제품 (오래된 생성일)") // 유효한 제품 (오래된 생성일)
          // 그 다음 만료된 제품들 (생성일 내림차순)
          XCTAssertEqual(products[2].name, "만료된 제품 (최신 생성일)") // 만료된 제품 (최신 생성일)
          XCTAssertEqual(products[3].name, "만료된 제품 (오래된 생성일)") // 만료된 제품 (오래된 생성일)
        }
      )
      .store(in: &self.cancellables)
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func test_fetchProducts_whenSortIsExpiration_shouldSortByExpirationDateAscending() {
    // Given
    let expectation = XCTestExpectation(description: "Products are sorted by expiration date")
    
    let now = Date()
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
    let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: now)!
    let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: now)!
    
    let product1 = createProduct(
      id: "1",
      name: "한달 뒤 만료",
      expirationDate: nextMonth,
      creationDate: now
    )
    
    let product2 = createProduct(
      id: "2",
      name: "일주일 뒤 만료",
      expirationDate: nextWeek,
      creationDate: now
    )
    
    let product3 = createProduct(
      id: "3",
      name: "내일 만료",
      expirationDate: tomorrow,
      creationDate: now
    )
    
    let product4 = createProduct(
      id: "4",
      name: "이미 만료됨",
      expirationDate: yesterday,
      creationDate: now
    )
    
    self.productRepository.fetchProductsResult = Just([product1, product2, product3, product4])
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // When
    self.sut.fetchProducts(sort: .expiration)
      .sink(
        receiveCompletion: { _ in
          expectation.fulfill()
        },
        receiveValue: { products in
          // Then
          XCTAssertEqual(products.count, 4)
          // name으로 비교
          XCTAssertEqual(products[0].name, "이미 만료됨") // 이미 만료됨 (가장 빠른 유통기한)
          XCTAssertEqual(products[1].name, "내일 만료") // 내일 만료
          XCTAssertEqual(products[2].name, "일주일 뒤 만료") // 일주일 뒤 만료
          XCTAssertEqual(products[3].name, "한달 뒤 만료") // 한달 뒤 만료 (가장 늦은 유통기한)
        }
      )
      .store(in: &self.cancellables)
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  // MARK: - Test fetchProduct(productID:) 메소드
  
  func test_fetchProductByID_shouldCallRepository() {
    // Given
    let expectation = XCTestExpectation(description: "Repository is called")
    let testID = DocumentID()
    
    self.productRepository.fetchProductByIDResult = Fail(error: NSError(domain: "test", code: 1))
      .eraseToAnyPublisher()
    
    // When
    self.sut.fetchProduct(productID: testID)
      .sink(
        receiveCompletion: { _ in
          expectation.fulfill()
        },
        receiveValue: { _ in }
      )
      .store(in: &self.cancellables)
    
    // Then
    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(self.productRepository.fetchProductByIDCallCount, 1)
  }
  
  // MARK: - Test fetchPinnedProducts 메소드
  
  func test_fetchPinnedProducts_shouldCallRepository() {
    // Given
    let expectation = XCTestExpectation(description: "Repository is called")
    
    self.productRepository.fetchPinnedProductsResult = Just([])
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // When
    self.sut.fetchPinnedProducts()
      .sink(
        receiveCompletion: { _ in
          expectation.fulfill()
        },
        receiveValue: { _ in }
      )
      .store(in: &self.cancellables)
    
    // Then
    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(self.productRepository.fetchPinnedProductsCallCount, 1)
  }
  
  // MARK: - Test fetchProduct(category:) 메소드
  
  func test_fetchProductByCategory_shouldCallRepository() {
    // Given
    let expectation = XCTestExpectation(description: "Repository is called")
    let category = ProductCategory.건강
    
    self.productRepository.fetchProductByCategoryResult = Just([])
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // When
    self.sut.fetchProduct(category: category)
      .sink(
        receiveCompletion: { _ in
          expectation.fulfill()
        },
        receiveValue: { _ in }
      )
      .store(in: &self.cancellables)
    
    // Then
    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(self.productRepository.fetchProductByCategoryCallCount, 1)
  }
  
  // MARK: - Test fetchProduct(keyword:) 메소드
  
  func test_fetchProductByKeyword_shouldCallRepository() {
    // Given
    let expectation = XCTestExpectation(description: "Repository is called")
    let keyword = "우유"
    
    self.productRepository.fetchProductByKeywordResult = Just([])
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    // When
    self.sut.fetchProduct(keyword: keyword)
      .sink(
        receiveCompletion: { _ in
          expectation.fulfill()
        },
        receiveValue: { _ in }
      )
      .store(in: &self.cancellables)
    
    // Then
    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(self.productRepository.fetchProductByKeywordCallCount, 1)
  }
}
