//
//  ProductViewController.swift
//  FreshNote
//
//  Created by SeokHyun on 11/14/24.
//

import Combine
import UIKit

import Kingfisher
import SnapKit

final class ProductViewController: BaseViewController, KeyboardEventable {
  enum Constant {
    static var pointString: Character { return "." }
  }
  
  // MARK: - Properties
  private let activityIndicatorView = ActivityIndicatorView()
  
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
    iv.layer.borderColor = UIColor(fnColor: .green1).cgColor
    iv.image = UIImage(systemName: "camera")?.withInsets(.init(top: 28, left: 28, bottom: 28, right: 28))
    iv.isUserInteractionEnabled = true
    return iv
  }()
  
  private let expirationLabel: UILabel = {
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
    let tf = PaddingTextField(clearButtonMode: .never)
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
    let tf = PaddingTextField(clearButtonMode: .never)
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
  
  private lazy var deleteButton: UIButton = {
    let button = UIButton()
    button.setTitle("삭제하기", for: .normal)
    button.setTitleColor(UIColor(fnColor: .littleWhite), for: .normal)
    button.backgroundColor = UIColor(fnColor: .delte).withAlphaComponent(0.8)
    button.layer.cornerRadius = 20
    button.layer.masksToBounds = true
    return button
  }()
  
  private var isCategoryToggleImageViewRotated: Bool = false
  
  private let descriptionTextView: PlaceholderTextView = {
    let tv = PlaceholderTextView(textContainerInset: .init(top: 20, left: 20, bottom: 20, right: 20))
    tv.font = UIFont.pretendard(size: 16, weight: ._500)
    tv.placeholder = "메모를 입력하세요."
    tv.layer.cornerRadius = 20
    tv.layer.borderWidth = 2
    tv.layer.borderColor = UIColor(fnColor: .green2).cgColor
    return tv
  }()
  
  private var saveButton: UIButton = {
    let btn = UIButton()
    btn.setTitle("저장", for: .normal)
    btn.setTitleColor(UIColor(fnColor: .gray0), for: .normal)
    btn.titleLabel?.font = UIFont.pretendard(size: 20, weight: ._600)
    return btn
  }()
  
  var transformView: UIView { self.view }
  
  private var expirationPreviousText = ""
  
  /// title의 키보드 input && programmatic value 주입에 대한 publisher입니다.
  private let titleTextFieldTextSubject: CurrentValueSubject<String, Never> = .init("")
  /// category의 키보드 input && programmatic value 주입에 대한 publisher입니다.
  private let categoryTextFieldTextSubject: CurrentValueSubject<String, Never> = .init("")
  
  private let mode: ProductViewModelMode
  
  // MARK: - LifeCycle
  init(
    viewModel: any ProductViewModel,
    mode: ProductViewModelMode
  ) {
    self.viewModel = viewModel
    self.mode = mode
    
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
    self.activityIndicatorView.stopIndicating()
    self.tabBarController?.tabBar.isHidden = false
  }
  
  deinit {
    print("DEBUG: \(Self.self) deinit")
  }
  
  // MARK: - SetupUI
  override func setupLayout() {
    defer {
      self.view.addSubview(self.activityIndicatorView)
      self.activityIndicatorView.snp.makeConstraints {
        $0.leading.trailing.bottom.equalToSuperview()
        $0.top.equalTo(self.view.safeAreaLayoutGuide)
      }
    }
    
    self.categoryTextField.addSubview(self.categoryToggleImageView)
    self.categoryToggleImageView.snp.makeConstraints {
      $0.trailing.equalToSuperview().inset(15.5)
      $0.size.equalTo(24)
      $0.centerY.equalToSuperview()
    }
    
    [
      self.titleTextField,
      self.imageView,
      self.expirationLabel,
      self.expirationWarningLabel,
      self.expirationTextField,
      self.categoryLabel,
      self.categoryTextField,
      self.descriptionTextView
    ].forEach {
      self.view.addSubview($0)
    }

    self.titleTextField.snp.makeConstraints { make in
      make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(10)
      make.centerX.equalTo(self.view.snp.centerX)
    }

    self.imageView.snp.makeConstraints { make in
      make.top.equalTo(self.titleTextField.snp.bottom).offset(23)
      make.width.equalTo(100)
      make.height.equalTo(self.imageView.snp.width)
      make.centerX.equalTo(self.view.snp.centerX)
    }

    self.expirationLabel.snp.makeConstraints { make in
      make.top.equalTo(self.imageView.snp.bottom).offset(45)
      make.leading.equalTo(self.view.snp.leading).offset(18)
    }

    self.expirationWarningLabel.snp.makeConstraints { make in
      make.centerY.equalTo(self.expirationLabel.snp.centerY)
      make.leading.equalTo(self.expirationLabel.snp.trailing).offset(10)
      make.trailing.lessThanOrEqualTo(self.view.snp.trailing).offset(-40)
    }

    self.expirationTextField.snp.makeConstraints { make in
      make.top.equalTo(self.expirationLabel.snp.bottom).offset(10)
      make.leading.equalTo(self.view.snp.leading).offset(16.5)
      make.trailing.equalTo(self.view.snp.trailing).offset(-16.5)
      make.height.equalTo(58)
    }

    self.categoryLabel.snp.makeConstraints { make in
      make.top.equalTo(self.expirationTextField.snp.bottom).offset(10)
      make.leading.equalTo(self.expirationLabel.snp.leading)
    }

    self.categoryTextField.snp.makeConstraints { make in
      make.top.equalTo(self.categoryLabel.snp.bottom).offset(10)
      make.leading.equalTo(self.expirationTextField.snp.leading)
      make.trailing.equalTo(self.expirationTextField.snp.trailing)
      make.height.equalTo(58)
    }
    
    switch self.mode {
    case .create:
      self.descriptionTextView.snp.makeConstraints { make in
        make.top.equalTo(self.categoryTextField.snp.bottom).offset(25)
        make.leading.equalTo(self.expirationTextField.snp.leading)
        make.trailing.equalTo(self.expirationTextField.snp.trailing)
        make.bottom.equalTo(self.view.safeAreaLayoutGuide).inset(46)
      }
    case .edit(_):
      self.descriptionTextView.snp.makeConstraints {
        $0.top.equalTo(self.categoryTextField.snp.bottom).offset(25)
        $0.leading.equalTo(self.expirationTextField.snp.leading)
        $0.trailing.equalTo(self.expirationTextField.snp.trailing)
      }
      
      self.view.addSubview(self.deleteButton)
      self.deleteButton.snp.makeConstraints {
        $0.top.equalTo(self.descriptionTextView.snp.bottom).offset(30)
        $0.leading.trailing.equalTo(self.descriptionTextView)
        $0.height.equalTo(60)
        $0.bottom.equalTo(self.view.safeAreaLayoutGuide).inset(46)
      }
    }
  }
}

private extension ProductViewController {
  // MARK: - Bind
  private func bind() {
    self.viewModel.errorPublisher
      .receive(on: DispatchQueue.main)
      .compactMap { $0 }
      .sink { [weak self] error in
        self?.activityIndicatorView.stopIndicating()
        switch (error as NSError).code {
        case 17020:
          AlertBuilder.presentNetworkErrorAlert(presentingViewController: self)
        default:
          AlertBuilder.presentDefaultError(presentingViewController: self, message: error.localizedDescription)
        }
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
        self?.categoryTextFieldTextSubject.send($0)
      }
      .store(in: &self.subscriptions)
    
    self.viewModel.imageDataPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] data in
        guard let data = data else {
          self?.imageView.image = UIImage(systemName: "camera")?
            .withInsets(.init(top: 28, left: 28, bottom: 28, right: 28))
          return
        }
        
        self?.imageView.image = UIImage(data: data)
      }
      .store(in: &self.subscriptions)
    
    self.viewModel.expirationPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] state in
        guard let self else { return }
        switch state {
        case .inCompleteDate(let text):
          self.expirationWarningLabel.text = text
          self.expirationWarningLabel.isHidden = false
        case .invalidDate(let text):
          self.expirationWarningLabel.text = text
          self.expirationWarningLabel.isHidden = false
        case .completeDate:
          self.expirationWarningLabel.isHidden = true
        case .writing:
          self.expirationWarningLabel.isHidden = true
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
        self?.isCategoryToggleImageViewRotated = true
        self?.animateCategoryToggleImageView()
      }
      .store(in: &self.subscriptions)
  }
  
  // MARK: - Actions
  private func bindAction() {
    // 유통기한 hidden && 유통기한 text가 존재하는 경우(유통기한 text는 didchange를 통해)
    let expirationCompletionPublisher = self.viewModel.expirationPublisher
      .map { state in
        guard case .completeDate = state else { return false }
        return true
      }
      .eraseToAnyPublisher()
    
    Publishers.CombineLatest3(
      self.titleTextFieldTextSubject,
      expirationCompletionPublisher,
      self.categoryTextFieldTextSubject
    )
    .receive(on: DispatchQueue.main)
    .map { titleText, isValidExpirationFormat, categoryText -> Bool in
      return !titleText.isEmpty && isValidExpirationFormat && !categoryText.isEmpty
    }
    .sink { [weak self] isValid in
      guard let self = self else { return }
      self.updateSaveButtonState(isValid)
    }
    .store(in: &self.subscriptions)
    
    self.expirationTextField.textEditingChangedPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] text in
        self?.viewModel.didChangeExpirationTextField(text)
      }
      .store(in: &self.subscriptions)
    
    self.backButton.tapPublisher
      .sink { [weak self] _ in
        self?.viewModel.didTapBackButton()
      }
      .store(in: &self.subscriptions)
    
    self.saveButton.tapThrottlePublisher
      .sink { [weak self] _ in
        self?.activityIndicatorView.startIndicating()
        
        guard let self = self,
              let name = self.titleTextField.text,
              let expiration = self.expirationTextField.text,
              let category = self.categoryTextField.text,
              let memo = self.descriptionTextView.text
        else { return }
        
        let imageData = self.makeImageData()
        self.viewModel.didTapSaveButton(
          name: name,
          expiration: expiration,
          imageData: imageData,
          category: category,
          memo: memo
        )
      }
      .store(in: &self.subscriptions)
    
    self.imageView.gesture()
      .sink { [weak self] _ in
        guard let self else { return }
        
        self.viewModel.didTapImageView(imageData: self.imageView.image?.jpegData(compressionQuality: 1.0))
      }
      .store(in: &self.subscriptions)
    
    self.categoryTextField.gesture()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.animateCategoryToggleImageView()
        self?.viewModel.didTapCategoryTextField()
      }
      .store(in: &self.subscriptions)
    
    self.titleTextField.textEditingChangedPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] text in
        self?.titleTextFieldTextSubject.send(text)
      }
      .store(in: &self.subscriptions)
    
    self.deleteButton.tapThrottlePublisher
      .sink { [weak self] _ in
        self?.activityIndicatorView.startIndicating()
        self?.viewModel.didTapDeleteButton()
      }
      .store(in: &self.subscriptions)
  }
}

// MARK: - Private Helpers
extension ProductViewController {
  private func makeImageData() -> Data? {
    if self.viewModel.isDefaultImage { // defaultImage인 경우
      return nil
    } else { // defaultImage가 아닌 경우
      if self.viewModel.isChangedImageIfNotDefaultImage { // 이미지가 변경된 경우
        return self.imageView.image?.jpegData(compressionQuality: 0.8)
      } else { // 이미지가 변경되지 않은 경우
        return nil
      }
    }
  }
  
  private func setupNavigationBar() {
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.saveButton)
    // UIBarButtonItem에 넣은 후에 isEnabled를 지정해야 정상 작동함..
    self.saveButton.isEnabled = false
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
      self.imageView.kf.indicatorType = .activity
      self.imageView.kf.setImage(with: url)
    }
    self.titleTextField.text = product.name
    self.titleTextFieldTextSubject.send(self.titleTextField.text ?? "")
    
    self.categoryTextField.text = product.category
    self.categoryTextFieldTextSubject.send(self.categoryTextField.text ?? "")
    
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
