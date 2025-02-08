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
  case noAuthorizationCode
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
  var activityIndicatePublisher: AnyPublisher<Bool, Never> { get }
}

enum OnboardingNextPage {
  case dateTimeSetting
  case home
}

final class DefaultOnboardingViewModel: NSObject {
  // MARK: - Properties
  private let actions: OnboardingViewModelActions
  private let signInUseCase: any SignInUseCase
  private let checkInitialStateUseCase: any CheckInitialStateUseCase
  
  fileprivate var currentNonce: String?
  
  private var subscriptions = Set<AnyCancellable>()
  
  private let dataSource: [OnboardingCellInfo] = {
    return [
      OnboardingCellInfo(
        description: "식품을 더 맛있게, 그리고 안전하게\n보관하기 위한 첫걸음",
        lottieName: "secondOnboardingLottie"
      ),
      OnboardingCellInfo(
        description: "내가 입력한 유통 & 소비기한으로\n원하는 디데이 알림을 받아보세요.",
        lottieName: "firstOnboardingLottie"
      )
    ]
  }()
  
  private var authController: ASAuthorizationController?
  
  // MARK: - Output
  var errorPublisher: AnyPublisher<(any Error)?, Never> { self.$error.eraseToAnyPublisher() }
  var activityIndicatePublisher: AnyPublisher<Bool, Never> { self.activityIndicateSubject.eraseToAnyPublisher() }
  
  @Published private var error: Error?
  private let activityIndicateSubject: PassthroughSubject<Bool, Never> = .init()
  
  // MARK: - LifeCycle
  init(
    actions: OnboardingViewModelActions,
    signInUseCase: any SignInUseCase,
    checkInitialStateUseCase: any CheckInitialStateUseCase
  ) {
    self.actions = actions
    self.signInUseCase = signInUseCase
    self.checkInitialStateUseCase = checkInitialStateUseCase
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
    
    let authController = ASAuthorizationController(authorizationRequests: [request])
    self.authController = authController
    return authController
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
    guard let authorizationCode = appleIDCredential.authorizationCode else {
      return .failure(AppleAuthorizationError.noAuthorizationCode)
    }
    
    let appleAuthProvider = AuthenticationProvider.apple(
      idToken: idTokenString,
      nonce: nonce,
      fullName: appleIDCredential.fullName,
      authorizationCode: authorizationCode
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
      self.activityIndicateSubject.send(true)
      
      return self.signInUseCase
        .signIn(authProvider: appleAuthProvider)
        .retry(3)
        .flatMap { [weak self] _ -> AnyPublisher<Bool, any Error> in
          guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
          
          // DateTime 설정 여부에 따라 화면 전환
          return self.checkInitialStateUseCase
            .checkDateTimeSetting()
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
          guard case let .failure(error) = completion else { return }
          self?.activityIndicateSubject.send(false)
          self?.error = error
        } receiveValue: { [weak self] isSavedDateTime in
          guard let self else { return }
          self.activityIndicateSubject.send(false)
          isSavedDateTime ? self.actions.showMain() : self.actions.showDateTimeSetting()
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
