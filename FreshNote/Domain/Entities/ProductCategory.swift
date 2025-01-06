//
//  ProductCategory.swift
//  FreshNote
//
//  Created by SeokHyun on 11/23/24.
//

import Foundation

enum ProductCategory: String, CaseIterable {
  case 과일
  case 채소
  case 정육_계란 = "정육 / 계란"
  case 수산_건어물 = "수산 / 건어물"
  case 쌀_잡곡 = "쌀 / 잡곡"
  case 견과
  case 반찬_간편식 = "반찬 / 간편식"
  case 건강
  case 면_통조림_가공식품 = "면 / 통조림 / 가공식품"
  case 샐러드_비건 = "샐러드 / 비건"
  case 생수_음료 = "생수 / 음료"
  case 치즈_유제품_스낵 = "치즈 / 유제품 / 스낵"
  case 소스_잼_장류 = "소스 / 잼 / 장류"
  case 냉동식품_밀키트 = "냉동식품 / 밀키트"
  case 주류
  case 기타
}
