////
////  SignInStateUseCase.swift
////  FreshNote
////
////  Created by SeokHyun on 12/15/24.
////
//
//import Combine
//import Foundation
//
//enum SignInStateUseCaseError: Error {
//  case failedToUpdate
//}
//
///// 로그인 상태를 관리합니다.
//protocol SignInStateUseCase {
//  func checkSignIn() -> AnyPublisher<Bool, any Error>
//  func updateSignInState(updateToValue: Bool) -> AnyPublisher<Void, any Error>
//  func saveSignInState() -> AnyPublisher<Void, any Error>
//}
//
//final class DefaultSignInStateUseCase: SignInStateUseCase {
//  private let signInStateRepository: any SignInStateRepository
//  
//  init(signInStateRepository: any SignInStateRepository) {
//    self.signInStateRepository = signInStateRepository
//  }
//  
//  func checkSignIn() -> AnyPublisher<Bool, any Error> {
//    return self.signInStateRepository.checkSignIn()
//  }
//  
//  func updateSignInState(updateToValue: Bool) -> AnyPublisher<Void, any Error> {
//    self.signInStateRepository.updateSignInState(updateToValue: updateToValue)
//      .mapError { error in
//        if case UserDefaultsError.failedToConvertData = error {
//          return SignInStateUseCaseError.failedToUpdate
//        }
//        return error
//      }
//      .eraseToAnyPublisher()
//  }
//  
//  func saveSignInState() -> AnyPublisher<Void, any Error> {
//    self.signInStateRepository.saveSignInState()
//  }
//}
