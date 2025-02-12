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
  private let activityIndicatorView = ActivityIndicatorView()
  
  private let viewModel: any CalendarViewModel
  
  private lazy var calendarView: UICalendarView = {
    let gregorianCalendar = Calendar(identifier: .gregorian)
    let calendarView = UICalendarView()
    calendarView.calendar = gregorianCalendar
    calendarView.locale = Locale(identifier: "ko_KR")
    calendarView.fontDesign = .default
    calendarView.delegate = self
    
    let selection = UICalendarSelectionMultiDate(delegate: self)
    calendarView.selectionBehavior = selection
    calendarView.tintColor = UIColor(fnColor: .green2)
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
  
  /// day를 선택했을 때 저장하는 변수입니다.
  private var selectedDayComponents: DateComponents? {
    didSet {
      if self.selectedDayComponents != nil {
        self.selectedMonthComponents = nil
      }
    }
  }
  
  /// day를 선택하지 않고 month만 선택했을 때 저장하는 변수입니다.
  private var selectedMonthComponents: DateComponents? {
    didSet {
      if self.selectedMonthComponents != nil {
        self.selectedDayComponents = nil
      }
    }
  }
  
  private var isSelectedDay: Bool {
    return self.selectedDayComponents != nil
  }
  
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
    
    if self.isSelectedDay, let selectedDayComponents = self.selectedDayComponents {
      self.viewModel.viewWillAppear(calendarDateComponents: .day(selectedDayComponents))
    } else if let selectedMonthComponents = self.selectedMonthComponents {
      self.viewModel.viewWillAppear(calendarDateComponents: .month(selectedMonthComponents))
    } else {
      self.viewModel.viewWillAppear(calendarDateComponents: .currentMonth)
    }
  }
  
  // MARK: - UI
  override func setupLayout() {
    defer {
      self.collectionView.addSubview(self.activityIndicatorView)
      self.activityIndicatorView.snp.makeConstraints {
        $0.edges.equalToSuperview()
      }
    }
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
    
    viewModel.reloadDecorationsPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] dateComponentsArray in
        self?.calendarView.reloadDecorations(forDateComponents: dateComponentsArray, animated: false)
      }
      .store(in: &self.subscriptions)
  }
}

// MARK: - UICalendarSelectionMultiDateDelegate
extension CalendarViewController: UICalendarSelectionMultiDateDelegate {
  func multiDateSelection(
    _ selection: UICalendarSelectionMultiDate,
    didSelectDate dateComponents: DateComponents
  ) {
    selection.selectedDates = [dateComponents]
    self.selectedDayComponents = dateComponents
    self.viewModel.didSelectDate(calendarDateComponents: .day(dateComponents))
  }
  
  func multiDateSelection(
    _ selection: UICalendarSelectionMultiDate,
    didDeselectDate dateComponents: DateComponents
  ) {
    self.viewModel.didDeselectDate(calendarDateComponents: .month(dateComponents))
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
    if let selection = self.calendarView.selectionBehavior as? UICalendarSelectionMultiDate {
      self.selectedDayComponents = nil
      self.selectedMonthComponents = calendarView.visibleDateComponents
      selection.setSelectedDates([], animated: false)
    }
    
    self.viewModel.didChangeVisibleDateComponents(
      calendarDateComponents: .month(calendarView.visibleDateComponents)
    )
  }
  
  func calendarView(
    _ calendarView: UICalendarView,
    decorationFor dateComponents: DateComponents
  ) -> UICalendarView.Decoration? {
    guard let targetDate = Calendar.current.date(from: dateComponents) else { return nil }
    
    return self.viewModel.hasEvent(decorationFor: targetDate)
    ? .default(color: UIColor.init(fnColor: .green2))
    : nil
  }
}
