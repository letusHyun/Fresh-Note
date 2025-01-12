//
//  DateTimeSettingViewController.swift
//  FreshNote
//
//  Created by SeokHyun on 10/22/24.
//

import Combine
import UIKit

final class DateTimeSettingViewController: BaseViewController {
  struct Constants {
    static let dateSize: CGFloat = 50
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
    textField.setPlaceholderColor(UIColor(fnColor: .gray2))
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
  
  private lazy var startButton: UIButton = {
    let button = UIButton()
    button.setTitle("시작하기", for: .normal)
    button.setTitleColor(UIColor(fnColor: .realBack), for: .normal)
    button.backgroundColor = self.startButtonDisabledColor
    button.layer.cornerRadius = 8
    button.layer.masksToBounds = true
    button.isEnabled = false
    return button
  }()
  
  private var startButtonDisabledColor: UIColor {
    UIColor(fnColor: .orange2).withAlphaComponent(0.3)
  }
  
  private var subscriptions: Set<AnyCancellable> = []
  
  private let viewModel: any DateTimeSettingViewModel
  
  // MARK: - LifeCycle
  init(viewModel: any DateTimeSettingViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }
  
  @MainActor required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.bindActions()
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    view.endEditing(true)
  }
  
  // MARK: - SetupUI
  override func setupLayout() {
    view.addSubview(self.descriptionLabel)
    view.addSubview(self.dateStackView)
    _=[self.dMinusLabel, self.dateTextField].map { self.dateStackView.addArrangedSubview($0) }
    view.addSubview(self.datePicker)
    view.addSubview(self.startButton)
    
    self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
    self.dateStackView.translatesAutoresizingMaskIntoConstraints = false
    self.datePicker.translatesAutoresizingMaskIntoConstraints = false
    self.startButton.translatesAutoresizingMaskIntoConstraints = false
    
    let safeArea = view.safeAreaLayoutGuide
    NSLayoutConstraint.activate([
      self.descriptionLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 250),
      self.descriptionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
    ] + [
      self.dateStackView.topAnchor.constraint(equalTo: self.descriptionLabel.bottomAnchor, constant: 40),
      self.dateStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
    ] + [
      self.datePicker.centerXAnchor.constraint(equalTo: self.dateStackView.centerXAnchor),
      self.datePicker.topAnchor.constraint(equalTo: self.dateStackView.bottomAnchor, constant: 40)
    ] + [
      self.startButton.heightAnchor.constraint(equalToConstant: 54),
      self.startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26.5),
      self.startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      self.startButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -60)
    ])
    
    self.dMinusLabel.widthAnchor.constraint(equalTo: self.dateStackView.widthAnchor, multiplier: 3/5).isActive = true
    self.dateTextField.widthAnchor.constraint(equalTo: self.dateStackView.widthAnchor, multiplier: 2/5).isActive = true
  }
  
  // MARK: - Privates
  private func bindActions() {
    self.startButton
      .tapPublisher
      .sink { [weak self] in
        guard let self else { return }
        let dateToInt = Int(self.dateTextField.text ?? "0") ?? 0
        self.viewModel.didTapStartButton(dateInt: dateToInt, hourMinuteDate: self.datePicker.date)
      }
      .store(in: &self.subscriptions)
    
    self.dateTextField
      .textPublisher
      .map { !$0.isEmpty }
      .sink { [weak self] isEnabled in
        self?.startButton.isEnabled = isEnabled
        self?.startButton.backgroundColor = isEnabled ?
        UIColor(fnColor: .orange2) :
        self?.startButtonDisabledColor
      }
      .store(in: &self.subscriptions)
  }
}

// MARK: - UITextFieldDelegate
extension DateTimeSettingViewController: UITextFieldDelegate {
  func textFieldDidEndEditing(_ textField: UITextField) {
    guard let text = textField.text else { return }
    
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
