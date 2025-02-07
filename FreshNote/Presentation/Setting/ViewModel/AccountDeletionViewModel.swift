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
  @Published private var error: (any Error)?
  var errorPublisher: AnyPublisher<(any Error)?, Never> { self.$error.eraseToAnyPublisher() }
  
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
    self.deleteAccountUseCase
      .deleteAccount()
      .receive(on: DispatchQueue.main)
      .catch { [weak self] error -> AnyPublisher<Void, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        
        // 재로그인이 필요한 경우
        if error.isRecentLoginRequiringError {
          return Future<Void, any Error> { promise in
            authController.delegate = self
            self.authPromise = promise // trigger 저장
            authController.performRequests()
          }
          .flatMap { _ in
            // re-delete 수행
            self.deleteAccountUseCase.redeleteAccount()
          }
          .eraseToAnyPublisher()
        }
        return Fail(error: error).eraseToAnyPublisher()
      }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] completion in
        guard case .failure(let error) = completion else { return }
        self?.error = error
      } receiveValue: { [weak self] _ in
        // TODO: - onboarding으로 이동해야 한다.
        self?.actions.deletionPop()
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
