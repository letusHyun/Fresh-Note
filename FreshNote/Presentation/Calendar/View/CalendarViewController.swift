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
    calendarView.selectionBehavior = UICalendarSelectionSingleDate(delegate: self)
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
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    self.viewModel.viewWillAppear()
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
extension CalendarViewController: UICalendarSelectionSingleDateDelegate {
  func dateSelection(
    _ selection: UICalendarSelectionSingleDate,
    didSelectDate dateComponents: DateComponents?
  ) {
    self.viewModel.didSelectDate(dateComponents: dateComponents)
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
