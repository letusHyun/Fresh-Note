//
//  AuthenticationProvider.swift
//  FreshNote
//
//  Created by SeokHyun on 12/13/24.
//

import Foundation

enum AuthenticationProvider {
  case apple(idToken: String, nonce: String, fullName: PersonNameComponents?)
  // kakao
  // google
  // naver
}
