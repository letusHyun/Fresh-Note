//
//  CalendarViewModel.swift
//  FreshNote
//
//  Created by SeokHyun on 10/28/24.
//

import Combine
import Foundation

struct CalendarViewModelActions {
  
}

protocol CalendarViewModelInput {
  func viewDidLoad()
  func cellForItem(at indexPath: IndexPath) -> Product
  func numberOfItemsInSection() -> Int
}

protocol CalendarViewModelOutput {
  
}

protocol CalendarViewModel: CalendarViewModelInput & CalendarViewModelOutput { }

final class DefaultCalendarViewModel: CalendarViewModel {

  
  // MARK: - Properties
  private let actions: CalendarViewModelActions
  
  private var mockModel = [Product]()
  
  
  // MARK: - Output
  
  // MARK: - LifeCycle
  init(actions: CalendarViewModelActions) {
    self.actions = actions
  }
  
  // MARK: - Input
  func viewDidLoad() {
    for i in 1...10 {
      var isPinned = false
      
      if i % 2 == 0 {
        isPinned.toggle()
      }
      
      self.mockModel.append(Product(
        did: .init(),
        name: "음식\(i)",
        expirationDate: Date(),
        category: "임시 카테고리",
        memo: "메모\(i)",
        imageURL: nil,
        isPinned: isPinned,
        creationDate: Date()
      ))
    }
  }
  
  func cellForItem(at indexPath: IndexPath) -> Product {
    return self.mockModel[indexPath.item]
  }
  
  func numberOfItemsInSection() -> Int {
    return self.mockModel.count
  }
}
