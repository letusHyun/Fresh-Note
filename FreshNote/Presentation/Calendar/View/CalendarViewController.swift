//
//  CalendarViewController.swift
//  FreshNote
//
//  Created by SeokHyun on 10/28/24.
//

import Combine
import Foundation
import UIKit

import SnapKit

final class CalendarViewController: BaseViewController {
  // MARK: - Properties
  private let viewModel: any CalendarViewModel
  
  private lazy var calendarView: UICalendarView = {
    let gregorianCalendar = Calendar(identifier: .gregorian)
    let calendarView = UICalendarView()
    calendarView.calendar = gregorianCalendar
    calendarView.locale = Locale(identifier: "ko_KR")
    calendarView.fontDesign = .default
    calendarView.delegate = self
//    calendarView.selectionBehavior = UICalendarSelectionSingleDate(delegate: self)
    
    let selection = UICalendarSelectionMultiDate(delegate: self)
    calendarView.selectionBehavior = selection
    
    return calendarView
  }()
  
  private lazy var collectionView: UICollectionView = {
    let layout =  UICollectionViewFlowLayout()
    layout.minimumInteritemSpacing = 10
    layout.minimumLineSpacing = 15
  
    let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
    cv.contentInset = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 30)
    cv.register(CalendarProductCell.self, forCellWithReuseIdentifier: CalendarProductCell.id)
    cv.dataSource = self
    cv.delegate = self
    return cv
  }()
  
  private var subscriptions: Set<AnyCancellable> = []
  
  /// date가 선택되었는지 판별하는 값입니다. nil이면 선택되지 않음을 의미합니다.
  // TODO: - erase
  private var selectedDateComponents: DateComponents? = nil
  
  // MARK: - LifeCycle
  init(viewModel: any CalendarViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }
  
  @MainActor required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    defer { self.viewModel.viewDidLoad() }
    
    self.bind(to: self.viewModel)
    self.setupNavigationBar()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    self.viewModel.viewWillAppear()
    // 현재 날짜가 선택됐는지 선택되지 않았는지 판별
      // 선택 됐으면 date 선택된 호출
      // 선택되지 않았으면 month 호출
    
    
    // 날짜 선택 판별 값은 선택된 date의 옵셔널로 지정
    // 값이 nil이면 선택되지 않음
    // 값이 존재하면 해당 날짜가 선택됨을 의미
  }
  
  // MARK: - UI
  override func setupLayout() {
    self.view.addSubview(self.calendarView)
    self.view.addSubview(self.collectionView)
    
    self.calendarView.snp.makeConstraints {
      $0.top.equalTo(self.view.safeAreaLayoutGuide)
      $0.leading.trailing.equalToSuperview()
    }
    
    self.collectionView.snp.makeConstraints {
      $0.top.equalTo(self.calendarView.snp.bottom)
      $0.leading.trailing.equalToSuperview()
      $0.bottom.equalTo(self.view.safeAreaLayoutGuide)
    }
  }
  
  // MARK: - Privates
  private func setupNavigationBar() {
    self.navigationItem.title = "캘린더"
  }
  
  private func bind(to viewModel: any CalendarViewModel) {
    viewModel.reloadDataPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.collectionView.reloadData()
      }
      .store(in: &self.subscriptions)
  }
}

// MARK: - UICalendarSelectionSingleDateDelegate
//extension CalendarViewController: UICalendarSelectionSingleDateDelegate {
//  func dateSelection(
//    _ selection: UICalendarSelectionSingleDate,
//    didSelectDate dateComponents: DateComponents?
//  ) {
//    guard let newDateComponents = dateComponents else {
//      return
//    }
//    let isSelectedDate = self.selectedDateComponents != nil
//    
//    // 선택된 날짜가 존재한다면
//    if let previousDateComponents = self.selectedDateComponents {
//      // 애니메이션 해제
//      selection.setSelected(nil, animated: true)
//      // 변수 선택되지 않음으로 변경
//      self.selectedDateComponents = nil
//      // month fetch
//      self.viewModel.didSelectDate(dateComponents: newDateComponents, isSelectedDate: isSelectedDate)
//    } else { // 선택된 날짜가 존재하지 않는다면
//      // 변수 선택으로 변경
//      self.selectedDateComponents = newDateComponents
//      // day fetch
//      self.viewModel.didSelectDate(dateComponents: newDateComponents, isSelectedDate: isSelectedDate)
//    }
//  }
//}

extension CalendarViewController: UICalendarSelectionMultiDateDelegate {
  func multiDateSelection(
    _ selection: UICalendarSelectionMultiDate,
    didSelectDate dateComponents: DateComponents
  ) {
    selection.selectedDates = [dateComponents]
    
    self.viewModel.didSelectDate(dateComponents: dateComponents)
  }
  
  func multiDateSelection(
    _ selection: UICalendarSelectionMultiDate,
    didDeselectDate dateComponents: DateComponents
  ) {
    self.viewModel.didDeselectDate(dateComponents: dateComponents)
  }
}

// MARK: - UICollectionViewDataSource
extension CalendarViewController: UICollectionViewDataSource {
  func collectionView(
    _ collectionView: UICollectionView,
    numberOfItemsInSection section: Int
  ) -> Int {
    return self.viewModel.numberOfItemsInSection()
  }
  
  func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: CalendarProductCell.id,
      for: indexPath
    ) as? CalendarProductCell else { return UICollectionViewCell() }
    
    let product = self.viewModel.cellForItem(at: indexPath)
    cell.configure(with: product)
    
    return cell
  }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension CalendarViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    guard let layout = collectionViewLayout as? UICollectionViewFlowLayout
    else { return CGSize(width: 0, height: 0) }
    
    let edgeInset = collectionView.contentInset.left + collectionView.contentInset.right
    let width: CGFloat = (self.view.bounds.width - edgeInset - layout.minimumInteritemSpacing) / 2
    return CGSize(width: width, height: 50)
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    self.viewModel.didSelectItem(at: indexPath)
  }
}

// MARK: - UICalendarViewDelegate
extension CalendarViewController: UICalendarViewDelegate {
  func calendarView(
    _ calendarView: UICalendarView,
    didChangeVisibleDateComponentsFrom previousDateComponents: DateComponents
  ) {
    self.viewModel.didChangeVisibleDateComponents(dateComponents: calendarView.visibleDateComponents)
  }
}
