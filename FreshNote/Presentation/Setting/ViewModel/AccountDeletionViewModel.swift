//
//  AccountDeletionViewModel.swift
//  FreshNote
//
//  Created by SeokHyun on 1/23/25.
//

import AuthenticationServices
import Combine
import CryptoKit
import Foundation

struct AccountDeletionViewModelActions {
  let deletionPop: () -> Void
}

protocol AccountDeletionViewModelOutput {
  var errorPublisher: AnyPublisher<(any Error)?, Never> { get }
  var activityIndicatePublisher: AnyPublisher<Bool, Never> { get }
}

protocol AccountDeletionViewModelInput {
  func didTapDeleteAccountButton(authController: ASAuthorizationController)
  func makeASAuthorizationController() -> ASAuthorizationController
}

protocol AccountDeletionViewModel: AccountDeletionViewModelInput & AccountDeletionViewModelOutput { }

final class DefaultAccountDeletionViewModel: NSObject, AccountDeletionViewModel {
  
  // MARK: - Properties
  private let actions: AccountDeletionViewModelActions
  private let deleteAccountUseCase: any DeleteAccountUseCase
  private let signInUseCase: any SignInUseCase
  
  private var subscriptions: Set<AnyCancellable> = []
  fileprivate var currentNonce: String?
  private var authController: ASAuthorizationController?
  
  private var authPromise: ((Result<Void, any Error>) -> Void)?
  
  // MARK: - Output
  var errorPublisher: AnyPublisher<(any Error)?, Never> { self.$error.eraseToAnyPublisher() }
  var activityIndicatePublisher: AnyPublisher<Bool, Never> { self.activityIndicateSubject.eraseToAnyPublisher() }
  
  @Published private var error: (any Error)?
  private let activityIndicateSubject: PassthroughSubject<Bool, Never> = .init()
  
  // MARK: - LifeCycle
  init(
    actions: AccountDeletionViewModelActions,
    deleteAccountUseCase: any DeleteAccountUseCase,
    signInUseCase: any SignInUseCase
  ) {
    self.actions = actions
    self.deleteAccountUseCase = deleteAccountUseCase
    self.signInUseCase = signInUseCase
  }
  
  // MARK: - Input
  func didTapDeleteAccountButton(authController: ASAuthorizationController) {
    return Future<Void, any Error> { promise in
      authController.delegate = self
      self.authPromise = promise // trigger 저장
      // 1. 재인증을 먼저 수행
      authController.performRequests()
    }
    .receive(on: DispatchQueue.main)
    .flatMap { [weak self] _ -> AnyPublisher<Void, any Error> in
      guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
      self.activityIndicateSubject.send(true)
      
      // 2. 재인증이 완료되면 계정탈퇴 수행
      return self.deleteAccountUseCase
        .execute()
    }
    .receive(on: DispatchQueue.main)
    .sink { [weak self] completion in
      guard case .failure(let error) = completion else { return }
      self?.error = error
    } receiveValue: { [weak self] _ in
      guard let self else { return }
      self.activityIndicateSubject.send(false)
      self.actions.deletionPop()
    }
    .store(in: &self.subscriptions)
  }
  
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
  
  // MARK: - Private
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
extension DefaultAccountDeletionViewModel: ASAuthorizationControllerDelegate {
  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithAuthorization authorization: ASAuthorization
  ) {
    switch self.makeAppleAuthProvider(from: authorization) {
    case let .success(appleAuthProvider):
      self.signInUseCase
        .reauthenticate(authProvider: appleAuthProvider)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
          guard case .failure(let error) = completion else { return }
          self?.authPromise?(.failure(error))
        } receiveValue: { [weak self] _ in
          self?.authPromise?(.success(()))
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
    self.authPromise?(.failure(error))
  }
}
