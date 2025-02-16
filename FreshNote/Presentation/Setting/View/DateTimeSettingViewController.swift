//
//  DateTimeSettingViewController.swift
//  FreshNote
//
//  Created by SeokHyun on 10/22/24.
//

import Combine
import UIKit

import SnapKit

final class DateTimeSettingViewController: BaseViewController {
  struct Constants {
    static var dateSize: CGFloat { 50 }
    static var completionButtonBottomConstraint: CGFloat { 50 }
  }
  
  // MARK: - Properties
  private let descriptionLabel: UILabel = {
    let label = UILabel()
    label.text = "원하는 날짜와 알람 시간을 지정해주세요."
    label.textAlignment = .center
    label.textColor = UIColor(fnColor: .gray3)
    label.font = .pretendard(size: 16, weight: ._400)
    return label
  }()
  
  private let dMinusLabel: UILabel = {
    let label = UILabel()
    label.text = "D - "
    label.textColor = UIColor(fnColor: .gray3)
    label.font = .pretendard(size: Constants.dateSize, weight: ._400)
    return label
  }()
  
  private lazy var dateTextField: UITextField = {
    let textField = UITextField()
    textField.placeholder = "01"
    textField.textColor = .black
    textField.font = .pretendard(size: Constants.dateSize, weight: ._400)
    textField.keyboardType = .numberPad
    textField.delegate = self
    textField.setPlaceholderColor(UIColor(fnColor: .gray2).withAlphaComponent(0.3))
    return textField
  }()
  
  private let dateStackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .horizontal
    return stackView
  }()
  
  private let datePicker: UIDatePicker = {
    let datePicker = UIDatePicker()
    datePicker.datePickerMode = .time
    datePicker.preferredDatePickerStyle = .compact
    return datePicker
  }()
  
  private lazy var completionButton: UIButton = {
    let button = UIButton()
    button.setTitle("시작하기", for: .normal)
    button.setTitleColor(UIColor(fnColor: .realBack), for: .normal)
    button.backgroundColor = self.completionButtonDisabledColor
    button.layer.cornerRadius = 15
    button.layer.masksToBounds = true
    button.isEnabled = false
    return button
  }()
  
  private var completionButtonDisabledColor: UIColor {
    UIColor(fnColor: .green2).withAlphaComponent(0.3)
  }
  
  private var subscriptions: Set<AnyCancellable> = []
  
  private let viewModel: any DateTimeSettingViewModel
  
  private var completionButtonBottomConstraint: NSLayoutConstraint?
  
  private let mode: DateTimeSettingViewModelMode
  
  private let endDateInformationLabel: UILabel = {
    let lb = UILabel()
    lb.font = UIFont.pretendard(size: 14, weight: ._400)
    lb.text = """
    * 유통기한 마감일에 알림 받기를 원하신다면,
    D-0으로 등록해주세요.
    """
    lb.textColor = UIColor(fnColor: .gray1)
    lb.numberOfLines = .zero
    lb.textAlignment = .center
    return lb
  }()
  
  // MARK: - LifeCycle
  init(viewModel: any DateTimeSettingViewModel, mode: DateTimeSettingViewModelMode) {
    self.viewModel = viewModel
    self.mode = mode
    super.init(nibName: nil, bundle: nil)
  }
  
  @MainActor required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    defer { self.viewModel.viewDidLoad() }
    
    self.bindActions()
    self.bind(to: self.viewModel)
    self.configure(with: self.mode)
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    self.view.endEditing(true)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    self.tabBarController?.tabBar.isHidden = true
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.tabBarController?.tabBar.isHidden = false
  }
  
  deinit {
    print("DEBUG: \(Self.self) deinit")
  }
  
  // MARK: - SetupUI
  override func setupLayout() {
    self.view.addSubview(self.descriptionLabel)
    self.view.addSubview(self.dateStackView)
    _=[self.dMinusLabel, self.dateTextField].map { self.dateStackView.addArrangedSubview($0) }
    self.view.addSubview(self.datePicker)
    self.view.addSubview(self.completionButton)
    self.view.addSubview(self.endDateInformationLabel)
    
    self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
    self.dateStackView.translatesAutoresizingMaskIntoConstraints = false
    self.datePicker.translatesAutoresizingMaskIntoConstraints = false
    self.completionButton.translatesAutoresizingMaskIntoConstraints = false
    
    let safeArea = view.safeAreaLayoutGuide
    NSLayoutConstraint.activate([
      self.descriptionLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 150),
      self.descriptionLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
    ] + [
      self.dateStackView.topAnchor.constraint(equalTo: self.descriptionLabel.bottomAnchor, constant: 40),
      self.dateStackView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
    ] + [
      self.datePicker.centerXAnchor.constraint(equalTo: self.dateStackView.centerXAnchor),
      self.datePicker.topAnchor.constraint(equalTo: self.dateStackView.bottomAnchor, constant: 40)
    ] + [
      self.completionButton.heightAnchor.constraint(equalToConstant: 54),
      self.completionButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 26.5),
      self.completionButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -26.5),
    ])
    self.completionButtonBottomConstraint = self.completionButton.bottomAnchor.constraint(
      equalTo: safeArea.bottomAnchor,
      constant: -Constants.completionButtonBottomConstraint
    )
    self.completionButtonBottomConstraint?.isActive = true
    
    self.dMinusLabel.widthAnchor.constraint(equalTo: self.dateStackView.widthAnchor, multiplier: 3/5).isActive = true
    self.dateTextField.widthAnchor.constraint(equalTo: self.dateStackView.widthAnchor, multiplier: 2/5).isActive = true
    
    self.endDateInformationLabel.snp.makeConstraints {
      $0.top.equalTo(self.datePicker.snp.bottom).offset(30)
      $0.centerX.equalToSuperview()
    }
  }
  
  // MARK: - Bind
  private func bind(to viewModel: any DateTimeSettingViewModel) {
    viewModel.errorPublisher
      .receive(on: DispatchQueue.main)
      .compactMap { $0 }
      .sink { [weak self] error in
        // TODO: - Error handling
      }
      .store(in: &self.subscriptions)
    
    viewModel.dateTimePublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] dateTime in
        self?.configureDateAndTime(with: dateTime)
      }
      .store(in: &self.subscriptions)
  }
  
  private func bindActions() {
    self.completionButton
      .tapThrottlePublisher
      .sink { [weak self] in
        guard let self else { return }
        let dateToInt = Int(self.dateTextField.text ?? "0") ?? 0
        self.viewModel.didTapCompletionButton(dateInt: dateToInt, hourMinuteDate: self.datePicker.date)
      }
      .store(in: &self.subscriptions)
    
    self.dateTextField
      .textEditingChangedPublisher
      .map { !$0.isEmpty }
      .sink { [weak self] isEnabled in
        self?.configureCompletionButton(isEnabled: isEnabled)
      }
      .store(in: &self.subscriptions)
    
    self.setupKeyboardBind()
  }
  
  private func setupKeyboardBind() {
    let keyboardWillShow = NotificationCenter.default.publisher(
      for: UIResponder.keyboardWillShowNotification
    )
    let keyboardWillHide = NotificationCenter.default.publisher(
      for: UIResponder.keyboardWillHideNotification
    )
    
    Publishers
      .Merge(keyboardWillShow, keyboardWillHide)
      .compactMap { [weak self] in
        return self?.calculateBottomOffset(for: $0)
      }
      .sink { [weak self] bottomOffset in
        self?.updateCompletionButtonConstraint(bottomOffset)
      }
      .store(in: &self.subscriptions)
  }
  
  // MARK: - Private
  private func configure(with mode: DateTimeSettingViewModelMode) {
    let buttonIsEnabled: Bool
    switch mode {
    case .edit:
      // button
      self.completionButton.setTitle("변경하기", for: .normal)
      buttonIsEnabled = true
    case .start:
      self.completionButton.setTitle("시작하기", for: .normal)
      buttonIsEnabled = false
    }
    
    self.configureCompletionButton(isEnabled: buttonIsEnabled)
  }
  
  private func configureCompletionButton(isEnabled: Bool) {
    self.completionButton.isEnabled = isEnabled
    self.completionButton.backgroundColor = isEnabled ?
    UIColor(fnColor: .green2) :
    self.completionButtonDisabledColor
  }
  
  private func calculateBottomOffset(for notification: Notification) -> CGFloat? {
    let isKeyboardShowing = notification.name == UIResponder.keyboardWillShowNotification
    
    if isKeyboardShowing {
      guard let keyboardFrame = notification
        .userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
        return nil
      }
      return keyboardFrame.height
    } else {
      return Constants.completionButtonBottomConstraint
    }
  }
  
  private func updateCompletionButtonConstraint(_ offset: CGFloat) {
    self.completionButtonBottomConstraint?.isActive = false
    let isKeyboardVisible = offset > Constants.completionButtonBottomConstraint
    
    let bottomAnchor = isKeyboardVisible ?
    self.view.bottomAnchor :
    self.view.safeAreaLayoutGuide.bottomAnchor
    
    self.completionButtonBottomConstraint = self.completionButton.bottomAnchor.constraint(
      equalTo: bottomAnchor,
      constant: -offset
    )
    
    self.completionButtonBottomConstraint?.isActive = true
    UIView.animate(withDuration: 0.3) {
      self.view.layoutIfNeeded()
    }
  }
  
  private func configureDateAndTime(with dateTime: DateTime) {
    self.dateTextField.text = "\(dateTime.date)"
    
    var components = DateComponents()
    components.hour = dateTime.hour
    components.minute = dateTime.minute
    
    guard let date = Calendar.current.date(from: components) else { return }
    self.datePicker.date = date
  }
}

// MARK: - UITextFieldDelegate
extension DateTimeSettingViewController: UITextFieldDelegate {
  func textFieldDidEndEditing(_ textField: UITextField) {
    guard let text = textField.text else { return }
    if text.count == 1, text != "0" {
      
    }
    if let first = text.first, first == "0", text.count == 2 {
      textField.text = String(text.dropFirst())
    }
  }
  
  func textField(
    _ textField: UITextField,
    shouldChangeCharactersIn range: NSRange,
    replacementString string: String
  ) -> Bool {
    let currentText = textField.text ?? ""
    let updatedText = (currentText as NSString).replacingCharacters(in: range, with: string)
    
    return updatedText.count <= 2
  }
}
