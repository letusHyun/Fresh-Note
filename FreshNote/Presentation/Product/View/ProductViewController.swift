//
//  ProductViewController.swift
//  FreshNote
//
//  Created by SeokHyun on 11/14/24.
//

import Combine
import UIKit

import SnapKit

final class ProductViewController: BaseViewController, KeyboardEventable {
  enum Constant {
    static var pointString: Character { return "." }
  }
  
  // MARK: - Properties
  private let viewModel: any ProductViewModel
  
  private let backButton = NavigationBackButton()
  
  var subscriptions = Set<AnyCancellable>()
  
  private let titleTextField: DynamicTextField = {
    let tf = DynamicTextField(borderColor: UIColor(fnColor: .gray3), widthConstant: 100)
    tf.textColor = .black
    tf.textAlignment = .center
    tf.font = UIFont.pretendard(size: 16, weight: ._500)
    tf.placeholder = "음식 이름"
    return tf
  }()
  
  private let imageView: UIImageView = {
    let iv = UIImageView()
    iv.contentMode = .scaleAspectFill
    iv.clipsToBounds = true
    iv.layer.cornerRadius = 8
    iv.layer.borderWidth = 2
    iv.layer.borderColor = UIColor(fnColor: .orange1).cgColor
    iv.image = UIImage(systemName: "camera")?.withInsets(.init(top: 28, left: 28, bottom: 28, right: 28))
    iv.isUserInteractionEnabled = true
    return iv
  }()
  
  private let expiration: UILabel = {
    let lb = UILabel()
    lb.text = "유통기한"
    lb.font = UIFont.pretendard(size: 12, weight: ._500)
    lb.textColor = .black
    return lb
  }()
  
  private let expirationWarningLabel: UILabel = {
    let lb = UILabel()
    lb.font = UIFont.pretendard(size: 12, weight: ._500)
    lb.textColor = .red
    lb.isHidden = true
    return lb
  }()
  
  private let categoryLabel: UILabel = {
    let lb = UILabel()
    lb.text = "카테고리"
    lb.font = UIFont.pretendard(size: 12, weight: ._500)
    lb.textColor = .black
    return lb
  }()
  
  private lazy var expirationTextField: PaddingTextField = {
    let tf = PaddingTextField()
    // TODO: - 현재 날자를 placeholder로 보여주는 알고리즘 작성하기
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy"
    let date = DateFormatManager().makeCurrentDate()
    let yearString = dateFormatter.string(from: date)
    
    tf.placeholder = String("ex)" + yearString.suffix(2) + ".01.01")
    tf.layer.cornerRadius = 8
    tf.layer.borderColor = UIColor(fnColor: .gray0).cgColor
    tf.layer.borderWidth = 1
    tf.keyboardType = .numberPad
    tf.delegate = self
    return tf
  }()
  
  private let categoryTextField: PaddingTextField = {
    let tf = PaddingTextField()
    tf.placeholder = "카테고리를 지정해주세요."
    tf.layer.cornerRadius = 8
    tf.layer.borderColor = UIColor(fnColor: .gray0).cgColor
    tf.layer.borderWidth = 1
    tf.inputView = UIView()
    return tf
  }()
  
  private let categoryToggleImageView: UIImageView = {
    let iv = UIImageView(image: UIImage(systemName: "chevron.down")?.withTintColor(
      UIColor(fnColor: .gray2),
      renderingMode: .alwaysOriginal
    ))
    return iv
  }()
  
  private var isCategoryToggleImageViewRotated: Bool = false
  
  private let descriptionTextView: PlaceholderTextView = {
    let tv = PlaceholderTextView()
    tv.textColor = UIColor(fnColor: .gray1)
    tv.font = UIFont.pretendard(size: 16, weight: ._500)
    tv.placeholder = "메모를 입력하세요."
    tv.layer.cornerRadius = 20
    tv.layer.borderWidth = 2
    tv.layer.borderColor = UIColor(fnColor: .orange2).cgColor
    return tv
  }()
  
  private var saveButton: UIButton = {
    let btn = UIButton()
    btn.setTitle("저장", for: .normal)
    btn.setTitleColor(UIColor(fnColor: .gray0), for: .normal)
    btn.titleLabel?.font = UIFont.pretendard(size: 20, weight: ._600)
    btn.isEnabled = false
    return btn
  }() {
    didSet {
      print("saveButton isEnabled changed to: \(saveButton.isEnabled)")
    }
  }
  
  var transformView: UIView { self.view }
  
  private var expirationPreviousText = ""
  
  // MARK: - LifeCycle
  init(viewModel: any ProductViewModel) {
    self.viewModel = viewModel
    
    super.init(nibName: nil, bundle: nil)
  }
  
  @MainActor required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupNavigationBar()
    self.bind()
    self.bindAction()
    self.bindKeyboard()
    self.viewModel.viewDidLoad()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.tabBarController?.tabBar.isHidden = true
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    ActivityIndicatorView.shared.stopIndicating()
    self.tabBarController?.tabBar.isHidden = false
  }
  
  // MARK: - SetupUI
  override func setupLayout() {
    _=[self.titleTextField,
       self.imageView,
       self.expiration,
       self.expirationWarningLabel,
       self.expirationTextField,
       self.categoryLabel,
       self.categoryTextField,
       self.descriptionTextView]
      .map {
        view.addSubview($0)
        $0.translatesAutoresizingMaskIntoConstraints = false
      }
    
    let safeArea = self.view.safeAreaLayoutGuide
    NSLayoutConstraint.activate([
      self.titleTextField.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 10),
      self.titleTextField.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
      
      self.imageView.topAnchor.constraint(equalTo: self.titleTextField.bottomAnchor, constant: 23),
      self.imageView.widthAnchor.constraint(equalToConstant: 100),
      self.imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
      self.imageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
      
      self.expiration.topAnchor.constraint(equalTo: self.imageView.bottomAnchor, constant: 45),
      self.expiration.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 18),
      
      self.expirationWarningLabel.centerYAnchor.constraint(equalTo: self.expiration.centerYAnchor),
      self.expirationWarningLabel.leadingAnchor.constraint(
        equalTo: self.expiration.trailingAnchor,
        constant: 10
      ),
      self.expirationWarningLabel.trailingAnchor.constraint(
        lessThanOrEqualTo: self.view.trailingAnchor,
        constant: -40
      ),
      
      self.expirationTextField.topAnchor.constraint(equalTo: self.expiration.bottomAnchor, constant: 10),
      self.expirationTextField.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16.5),
      self.expirationTextField.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16.5),
      self.expirationTextField.heightAnchor.constraint(equalToConstant: 58),
      
      self.categoryLabel.topAnchor.constraint(equalTo: self.expirationTextField.bottomAnchor, constant: 10),
      self.categoryLabel.leadingAnchor.constraint(equalTo: self.expiration.leadingAnchor),
      
      self.categoryTextField.topAnchor.constraint(equalTo: self.categoryLabel.bottomAnchor, constant: 10),
      self.categoryTextField.leadingAnchor.constraint(equalTo: self.expirationTextField.leadingAnchor),
      self.categoryTextField.trailingAnchor.constraint(equalTo: self.expirationTextField.trailingAnchor),
      self.categoryTextField.heightAnchor.constraint(equalToConstant: 58),
      
      self.descriptionTextView.topAnchor.constraint(equalTo: self.categoryTextField.bottomAnchor, constant: 25),
      self.descriptionTextView.leadingAnchor.constraint(equalTo: self.expirationTextField.leadingAnchor),
      self.descriptionTextView.trailingAnchor.constraint(equalTo: self.expirationTextField.trailingAnchor),
      self.descriptionTextView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -46)
    ])
    
    self.categoryTextField.addSubview(self.categoryToggleImageView)
    self.categoryToggleImageView.snp.makeConstraints {
      $0.trailing.equalToSuperview().inset(15.5)
      $0.size.equalTo(24)
      $0.centerY.equalToSuperview()
    }
  }
}

private extension ProductViewController {
  // MARK: - Bind
  private func bind() {
    self.viewModel.errorPublisher
      .receive(on: DispatchQueue.main)
      .sink { error in
        guard let error = error else { return }
        ActivityIndicatorView.shared.stopIndicating()
        // TODO: - error handling
      }
      .store(in: &self.subscriptions)
    
    self.viewModel.categoryToggleAnimationPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in
        self?.animateCategoryToggleImageView()
      }
      .store(in: &self.subscriptions)
    
    self.viewModel.categoryPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in
        self?.categoryTextField.text = $0
      }
      .store(in: &self.subscriptions)
    
    self.viewModel.imageDataPublisher
      .receive(on: DispatchQueue.main)
      .compactMap { $0 }
      .sink { [weak self] data in
        self?.imageView.image = UIImage(data: data)
      }
      .store(in: &self.subscriptions)
    
    self.viewModel.expirationPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] state in
        switch state {
        case .inCompleteDate(let text):
          self?.expirationWarningLabel.text = text
          self?.expirationWarningLabel.isHidden = false
        case .invalidDate(let text):
          self?.expirationWarningLabel.text = text
          self?.expirationWarningLabel.isHidden = false
        case .completeDate:
          self?.expirationWarningLabel.isHidden = true
        case .writing:
          self?.expirationWarningLabel.isHidden = true
        }
      }
      .store(in: &self.subscriptions)
    
    self.viewModel.expirationTextPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] text in
        self?.expirationTextField.text = text
      }
      .store(in: &self.subscriptions)
    
    self.viewModel.setupProductPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] product in
        self?.setupEditUI(with: product)
      }
      .store(in: &self.subscriptions)
  }
  
  // MARK: - Actions
  private func bindAction() {
    // 유통기한 hidden && 유통기한 text가 존재하는 경우(유통기한 text는 didchange를 통해)
    let expirationPublisher = self.viewModel.expirationPublisher
      .map { state in
        guard case .completeDate = state else { return false }
        return true
      }
      .eraseToAnyPublisher()
    
    Publishers.CombineLatest3(
      self.titleTextField.textDidChangedPublisher,
      expirationPublisher,
      // 카테고리TextField는 키보드를 사용하지 않고 programatically로 text값 변경
      self.categoryTextField.publisher(for: \.text).eraseToAnyPublisher()
    )
    .receive(on: DispatchQueue.main)
    .compactMap { titleText, isValidExpirationFormat, categoryText -> Bool? in
      guard let text = categoryText else { return nil }
      return !titleText.isEmpty && isValidExpirationFormat && !text.isEmpty
    }
    .sink { [weak self] isValid in
      guard let self = self else { return }
      self.updateSaveButtonState(isValid)
    }
    .store(in: &self.subscriptions)
    
    self.expirationTextField.textDidChangedPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] text in
        self?.viewModel.didChangeExpirationTextField(text)
      }
      .store(in: &self.subscriptions)
    
    self.backButton.publisher(for: .touchUpInside)
      .sink { [weak self] _ in
        self?.viewModel.didTapBackButton()
      }
      .store(in: &self.subscriptions)
    
    self.saveButton.publisher(for: .touchUpInside)
      .sink { [weak self] _ in
        print("is enabled?: \(self?.saveButton.isEnabled)")
        ActivityIndicatorView.shared.startIndicating()
        
        guard let self = self,
              let name = self.titleTextField.text,
              let expiration = self.expirationTextField.text,
              let category = self.categoryTextField.text,
              let memo = self.descriptionTextView.text
        else { return }
        
        let imageData = self.viewModel.isCustomImage
        ? self.imageView.image?.jpegData(compressionQuality: 0.8)
        : nil
        
        self.viewModel.didTapSaveButton(
          name: name,
          expiration: expiration,
          imageData: imageData,
          category: category,
          memo: memo
        )
      }
      .store(in: &self.subscriptions)
    
    self.imageView.publisher(for: UITapGestureRecognizer())
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.viewModel.didTapImageView()
      }
      .store(in: &self.subscriptions)
    
    self.categoryTextField.publisher(for: UITapGestureRecognizer())
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.animateCategoryToggleImageView()
        self?.viewModel.didTapCategoryTextField()
      }
      .store(in: &self.subscriptions)
  }
}

// MARK: - Private Helpers
extension ProductViewController {
  private func setupNavigationBar() {
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.saveButton)
    self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: self.backButton)
  }
  
  private func animateCategoryToggleImageView() {
    UIView.animate(withDuration: 0.3) {
      let transform = self.isCategoryToggleImageViewRotated ? .identity : CGAffineTransform(rotationAngle: .pi)
      self.categoryToggleImageView.transform = transform
      self.isCategoryToggleImageViewRotated.toggle()
    }
  }
  
  private func setupEditUI(with product: Product) {
    if let url = product.imageURL {
      URLSession.shared.dataTaskPublisher(for: url)
        .map { UIImage(data: $0.data) }
        .replaceError(with: nil)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] image in
          self?.imageView.image = image
        }
        .store(in: &self.subscriptions)
    }
    self.titleTextField.text = product.name
    self.categoryTextField.text = product.category
    
    let dateFormatManager = DateFormatManager()
    self.expirationTextField.text = dateFormatManager.string(from: product.expirationDate)
    self.descriptionTextView.text = product.memo
    self.descriptionTextView.updatePlaceholderVisibility()
    self.updateSaveButtonState(true)
  }
  
  private func updateSaveButtonState(_ isValid: Bool) {
    self.saveButton.isEnabled = isValid
    if isValid {
      self.saveButton.setTitleColor(UIColor(fnColor: .gray3), for: .normal)
    } else {
      self.saveButton.setTitleColor(UIColor(fnColor: .gray0), for: .normal)
    }
  }
}

// MARK: - UITextFieldDelegate
extension ProductViewController: UITextFieldDelegate {
  func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
    if textField === self.expirationTextField {
      self.viewModel.expirationTextFieldShouldEndEditing(textField.text)
    }
    
    return true
  }
}
