//
//  OnboardingViewModel.swift
//  FreshNote
//
//  Created by SeokHyun on 10/21/24.
//

import AuthenticationServices
import Combine
import CryptoKit
import Foundation

import FirebaseAuth

enum AppleAuthorizationError: Error {
  case invalIDState
  case invalidAppleIDToken
  case faildToConvertIDTokenString
  case currentNonceIsNil
}

struct OnboardingViewModelActions {
  let showDateTimeSetting: () -> Void
  let showMain: () -> Void
}

protocol OnboardingViewModel: OnboardingViewModelInput, OnboardingViewModelOutput { }

protocol OnboardingViewModelInput {
  func makeASAuthorizationController() -> ASAuthorizationController
  func viewDidLoad()
  func numberOfItemsInSection(sectionIndex: Int) -> Int
  func dataSourceCount() -> Int
  func cellForItemAt(indexPath: IndexPath) -> OnboardingCellInfo
  func didTapAppleButton(authController: ASAuthorizationController)
}

protocol OnboardingViewModelOutput {
  var errorPublisher: AnyPublisher<(any Error)?, Never> { get }
}

final class DefaultOnboardingViewModel: NSObject {
  // MARK: - Properties
  fileprivate var currentNonce: String?
  
  private var subscriptions = Set<AnyCancellable>()
  
  private let dataSource: [OnboardingCellInfo] = {
    return [
      OnboardingCellInfo(
        description: "내가 입력한 유통 & 소비기한으로\n원하는 디데이 알림을 받아보세요.",
        lottieName: "firstOnboardingLottie"
      ),
      OnboardingCellInfo(
        description: "식품을  더 맛있게, 그리고 안전하게\n보관하기 위한  첫걸음",
        lottieName: "secondOnboardingLottie"
      )
    ]
  }()
  
  private let actions: OnboardingViewModelActions
  private let saveUserProfileUseCase: any SaveUserProfileUseCase
  private let signInUseCase: any SignInUseCase
  private let checkDateTimeStateUseCase: any CheckDateTimeStateUseCase
  private let signInStateUseCase: any SignInStateUseCase
  
  // MARK: - Output
  var errorPublisher: AnyPublisher<(any Error)?, Never> {
    self.$error.eraseToAnyPublisher()
  }
  
  @Published private var error: Error?
  
  // MARK: - LifeCycle
  init(
    actions: OnboardingViewModelActions,
    signInUseCase: any SignInUseCase,
    signInStateUseCase: any SignInStateUseCase,
    checkDateTimeStateUseCase: any CheckDateTimeStateUseCase,
    saveUserProfileUseCase: any SaveUserProfileUseCase
  ) {
    self.actions = actions
    self.signInUseCase = signInUseCase
    self.signInStateUseCase = signInStateUseCase
    self.checkDateTimeStateUseCase = checkDateTimeStateUseCase
    self.saveUserProfileUseCase = saveUserProfileUseCase
  }
}

// MARK: - Input
extension DefaultOnboardingViewModel: OnboardingViewModel {
  func makeASAuthorizationController() -> ASAuthorizationController {
    let appleIDProvider = ASAuthorizationAppleIDProvider()
    let nonce = self.randomNonceString()
    self.currentNonce = nonce
    let request = appleIDProvider.createRequest()
    request.requestedScopes = [.fullName, .email]
    request.nonce = self.sha256(nonce)
    
    return ASAuthorizationController(authorizationRequests: [request])
  }
  
  func didTapAppleButton(authController: ASAuthorizationController) {
    authController.delegate = self
    authController.performRequests()
  }

  func cellForItemAt(indexPath: IndexPath) -> OnboardingCellInfo {
    return dataSource[indexPath.item]
  }
  
  func viewDidLoad() {
    
  }
  
  func numberOfItemsInSection(sectionIndex: Int) -> Int {
    return dataSource.count
  }
  
  func dataSourceCount() -> Int {
    return dataSource.count
  }
}

// MARK: - Private Helpers
extension DefaultOnboardingViewModel {
  private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    var randomBytes = [UInt8](repeating: 0, count: length)
    let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
    if errorCode != errSecSuccess {
      fatalError(
        "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
      )
    }
    
    let charset: [Character] =
    Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    
    let nonce = randomBytes.map { byte in
      charset[Int(byte) % charset.count]
    }
    
    return String(nonce)
  }
  
  @available(iOS 13, *)
  private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
      String(format: "%02x", $0)
    }.joined()
    
    return hashString
  }
  
  private func makeAppleAuthProvider(
    from authorization: ASAuthorization
  ) -> Result<AuthenticationProvider, any Error> {
    guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
      return .failure(AppleAuthorizationError.invalIDState)
    }
    
    guard let nonce = self.currentNonce else {
      return .failure(AppleAuthorizationError.currentNonceIsNil)
    }
    guard let appleIDToken = appleIDCredential.identityToken else {
      return .failure(AppleAuthorizationError.invalidAppleIDToken)
    }
    guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
      return .failure(AppleAuthorizationError.faildToConvertIDTokenString)
    }
    
    let appleAuthProvider = AuthenticationProvider.apple(
      idToken: idTokenString,
      nonce: nonce,
      fullName: appleIDCredential.fullName
    )
    return .success(appleAuthProvider)
  }
}

// MARK: - ASAuthorizationControllerDelegate
extension DefaultOnboardingViewModel: ASAuthorizationControllerDelegate {
  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithAuthorization authorization: ASAuthorization
  ) {
    switch self.makeAppleAuthProvider(from: authorization) {

    case let .success(appleAuthProvider):
      return self.signInUseCase
        .signIn(authProvider: appleAuthProvider)
        .retry(3)
        .flatMap { [weak self] _ -> AnyPublisher<Void, any Error> in
          guard let self else { return Empty().eraseToAnyPublisher() }
          
          return self.signInStateUseCase.updateSignInState(updateToValue: true)
        }
        .catch { [weak self] error -> AnyPublisher<Void, any Error> in
          guard let self else { return Empty().eraseToAnyPublisher() }
          
          if case SignInStateUseCaseError.failedToUpdate = error {
            return self.signInStateUseCase
              .saveSignInState()
          }
          return Fail(error: error)
            .eraseToAnyPublisher()
        }
        .flatMap { [weak self] _ -> AnyPublisher<Bool, any Error> in
          guard let self else { return Empty().eraseToAnyPublisher() }
          
          return self.checkDateTimeStateUseCase.execute()
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
          guard case let .failure(error) = completion else { return }
          self?.error = error
        } receiveValue: { [weak self] isSavedDateTime in
          // TODO: - SignIn을 통해 로그인 성공하면 로그인 최초 로그인인지 아니면, 로그인 경력이 있는지 확인해야 함
          isSavedDateTime ? self?.actions.showMain() : self?.actions.showDateTimeSetting()
        }
        .store(in: &self.subscriptions)
      
    case let .failure(error):
      self.error = error
    }
  }
  
  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithError error: any Error
  ) {
    self.error = error
  }
}
