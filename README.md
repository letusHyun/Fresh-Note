# 🍃 Fresh Note - 신선함을 담는 메모장

<img width="77" alt="iOS 16.0" src="https://img.shields.io/badge/iOS-16.0+-silver"> <img width="83" alt="Xcode 16.1" src="https://img.shields.io/badge/Xcode-15.2-blue"> <img width="77" alt="Swift 5.0" src="https://img.shields.io/badge/Swift-5.9-orange">

<div align="center">
  <img src="https://github.com/user-attachments/assets/placeholder_main_image.png" width=900>

  #### 유통기한과 레시피를 한 눈에, 신선한 식재료 관리를 위한 솔루션<br>
  #### 식재료 관리부터 레시피 추천까지, 당신의 냉장고를 스마트하게 - **Fresh Note 🍃**

</div>

<br>

## 🌱 Fresh Note 화면


|![검색 화면](https://github.com/user-attachments/assets/8818bca7-ac94-418e-8e43-4712b72b50eb)|![스마트 알림](https://github.com/user-attachments/assets/feature2_placeholder.png)|![레시피 추천](https://github.com/user-attachments/assets/feature3_placeholder.png)|
|:-:|:-:|:-:|
|**식재료 관리**<br>유통기한 추적|**스마트 알림**<br>임박한 유통기한 알림|**레시피 추천**<br>보유 식재료 기반|
|![바코드 스캔](https://github.com/user-attachments/assets/feature4_placeholder.png)|![소비 통계](https://github.com/user-attachments/assets/feature5_placeholder.png)|![장보기 목록](https://github.com/user-attachments/assets/feature6_placeholder.png)|
|**바코드 스캔**<br>간편한 식재료 등록|**소비 통계**<br>식재료 사용 패턴 분석|**장보기 목록**<br>필요한 식재료 관리|

##

### 🧱 아키텍처

> ### Clean Architecture + MVVM-C

<div align="center">

<img width="800" alt="아키텍처" src="https://github.com/user-attachments/assets/architecture_placeholder.png">

</div>

- **Coordinator 패턴**으로 화면 전환 로직을 분리하여 View Controller의 책임 감소
  
- **Repository 패턴**을 활용한 Data Layer를 통해 데이터 소스 추상화
  
- **Use Case**를 통한 비즈니스 로직 분리로 ViewModel 복잡도 감소

- **Protocol 기반 의존성 주입**으로 테스트 용이성 확보

##

### 🛠️ 기술 스택

### Firebase
- Authentication, Firestore, Storage를 활용한 서버리스 아키텍처 구현
- 별도의 백엔드 서버 없이 데이터 동기화 및 사용자 인증 구현
- Cloud Functions를 통한 서버 측 로직 처리 (푸시 알림, 데이터 처리)

### Combine & Async/Await
- 데이터 바인딩과 비동기 이벤트 처리를 위한 Combine 프레임워크 활용
- 비동기 네트워크 요청 및 DB 작업에 Swift Concurrency 적용
- Combine과 Async/Await의 상호 운용성 확보를 위한 연결 레이어 구현

### CoreData & Keychain
- 오프라인 모드 지원을 위한 CoreData 활용
- 민감한 인증 정보를 안전하게 저장하기 위한 Keychain Services 구현
- Firebase와 Local DB 간 데이터 동기화 메커니즘 구현

##

### 📋 구현 내용

#### 1. 애플 로그인 구현
- JWT 생성을 서버가 아닌 클라이언트에서 직접 처리하는 보안 아키텍처 구현
- Keychain을 활용한 Refresh Token 저장으로 사용자 재로그인 필요성 최소화
- Firebase와의 통합을 통한 자동 로그인 구현

#### 2. 맥락별 푸시 알림 복원 전략
- 앱 삭제/재설치 시나리오에서도 사용자 설정 기반 푸시 알림 복원
- Keychain을 활용한 상태 정보 보존으로 일관된 사용자 경험 제공
- 12가지 사용자 시나리오 분석 및 대응 로직 구현

#### 3. Firestore 비용 최적화
- 로컬 캐싱 우선 전략을 통한 Firestore 읽기 비용 절감
- 효율적인 데이터 동기화 메커니즘으로 네트워크 트래픽 최소화
- 단일 데이터 소스 원칙 적용으로 일관된 데이터 상태 유지

##

### 🧑‍💻 개발자

<div align="center">

|🍎 김석현|
</div>

##

<div align="center">
  
|📑 문서|[기술 블로그](https://medium.com/@blog_url)|[포트폴리오](https://notion_url)|
|:-:|:-:|:-:|

</div> 

## 📱 Fresh Note 화면

<div align="center">
  <table>
    <tr>
      <td align="center"><img src="https://github.com/user-attachments/assets/83a6c5c7-7529-4321-baa0-62851b9a062b" width="200"/><br><b>로그인 화면</b></td>
      <td align="center"><img src="https://github.com/user-attachments/assets/44ea51ab-5a47-411f-adc5-9c3170e8e5e8" width="200"/><br><b>홈 화면</b></td>
      <td align="center"><img src="https://github.com/user-attachments/assets/37550544-c6fe-456e-8dd0-0b9770f566be" width="200"/><br><b>제품 등록 화면</b></td>
      <td align="center"><img src="https://github.com/user-attachments/assets/4ba75f64-43f3-40ce-81b9-0eec3534401b" width="200"/><br><b>사진 바텀시트 화면</b></td>
    </tr>
    <tr>
      <td align="center"><img src="https://github.com/user-attachments/assets/023baa3b-b432-4c5a-bddf-31a6c9156d38" width="200"/><br><b>사진 전체 화면</b></td>
      <td align="center"><img src="https://github.com/user-attachments/assets/ddb595bb-47f0-4ec9-877b-b1f0a80c46a1" width="200"/><br><b>검색 화면</b></td>
      <td align="center"><img src="https://github.com/user-attachments/assets/b8ba88d5-57fd-4807-8c04-159f8828d55a" width="200"/><br><b>캘린더 화면</b></td>
      <td align="center"><img src="https://github.com/user-attachments/assets/8b87f020-19c3-436d-95f5-916290fce4cc" width="200"/><br><b>핀 화면</b></td>
    </tr>
    <tr>
      <td align="center"><img src="https://github.com/user-attachments/assets/71f5bf7d-a044-4b4f-9984-558aea2a4689" width="200"/><br><b>카테고리 화면</b></td>
      <td align="center"><img src="https://github.com/user-attachments/assets/6d3ef3d5-4f59-4d35-a269-0fc4ba8d95f5" width="200"/><br><b>버전 정보 화면</b></td>
      <td align="center"><img src="https://github.com/user-attachments/assets/f04f98fa-36da-4113-95aa-391e10d38950" width="200"/><br><b>로그아웃 화면</b></td>
      <td align="center"><img src="https://github.com/user-attachments/assets/8bdae28c-ea20-4a6c-8179-9818d3cf38d8" width="200"/><br><b>회원탈퇴 화면</b></td>
    </tr>
  </table>
</div>
