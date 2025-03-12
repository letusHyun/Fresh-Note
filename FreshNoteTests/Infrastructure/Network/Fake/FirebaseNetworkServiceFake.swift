//
//  FirebaseNetworkServiceFake.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 12/18/24.
//

@testable import Fresh_Note_Dev
import Combine
import Foundation

enum FirebaseNetworkServiceFakeError: Error {
  case transformError
}

final class FirebaseNetworkServiceFake: FirebaseNetworkService {
  /// Document 데이터를 저장하는 in memory 저장소입니다.
  ///
  /// key: DocumentPath
  ///
  /// value: Data
  private var documentStore: [String: Data] = [:]
  /// Storage 데이터를 저장하는 in memory 저장소입니다.
  private var fileStore: [String: Data] = [:]
  
  func getDocument<T: Decodable>(documentPath: String) -> AnyPublisher<T, any Error> {
    return Future { [weak self] promise in
      guard let documentData = self?.documentStore[documentPath] else {
        return promise(.failure(FirebaseNetworkServiceError.encodingError))
      }
      
      do {
        let decodedData = try JSONDecoder().decode(T.self, from: documentData)
        return promise(.success(decodedData))
      } catch {
        return promise(.failure(error))
      }
    }
    .eraseToAnyPublisher()
  }
  
  func getDocuments<T: Decodable>(collectionPath: String) -> AnyPublisher<[T], any Error> {
    return Future { [weak self] promise in
      let collectionDocuments = self?.documentStore.filter { key, _ in
        key.starts(with: collectionPath)
      }
      
      do {
        let decodedDocuments: [T] = try collectionDocuments?.compactMap { _, documentData in
          try JSONDecoder().decode(T.self, from: documentData)
        } ?? []
        return promise(.success(decodedDocuments))
      } catch {
        return promise(.failure(error))
      }
    }
    .eraseToAnyPublisher()
  }
  
  func setDocument<T: Encodable>(
    documentPath: String,
    requestDTO: T,
    merge: Bool
  ) -> AnyPublisher<Void, any Error> {
    return Future { [weak self] promise in
      do {
        let encoder = JSONEncoder()
        let newData = try encoder.encode(requestDTO)
        
        if merge, let existingData = self?.documentStore[documentPath] {
          guard let existingDict = try JSONSerialization.jsonObject(with: existingData) as? [String: Any],
                let newDict = try JSONSerialization.jsonObject(with: newData) as? [String: Any] else {
            throw FirebaseNetworkServiceFakeError.transformError
          }
          
          // 기존 딕셔너리를 유지하면서 새로운 필드만 업데이트
          var mergeDict = existingDict
          newDict.forEach { key, value in
            mergeDict[key] = value
          }
          
          // merged된 딕셔너리를 Data로 변환해서 저장
          let mergedData = try JSONSerialization.data(withJSONObject: mergeDict)
          self?.documentStore[documentPath] = mergedData
        } else { // merge가 false이거나 기존에 데이터가 없으면, 새 데이터로 덮어쓰기
          self?.documentStore[documentPath] = newData
        }
        
        return promise(.success(()))
      } catch {
        return promise(.failure(error))
      }
    }
    .eraseToAnyPublisher()
  }
  
  func uploadData(path: String, fileName: String, data: Data) -> AnyPublisher<URL, any Error> {
    return Future { [weak self] promise in
      let filePath = "\(path)/\(fileName)"
      self?.fileStore[filePath] = data
      
      guard let fakeURL = URL(string: "\(filePath)") else {
        return promise(.failure(FirebaseNetworkServiceError.dataUploadFailed))
      }
      return promise(.success(fakeURL))
    }
    .eraseToAnyPublisher()
  }
  
  func deleteData(urlString: String) -> AnyPublisher<Void, any Error> {
    return Future { [weak self] promise in
      self?.fileStore[urlString] = nil
      return promise(.success(()))
    }
    .eraseToAnyPublisher()
  }
  
  func deleteDocument(documentPath: String) -> AnyPublisher<Void, any Error> {
    return Future { [weak self] promise in
      self?.documentStore[documentPath] = nil
      return promise(.success(()))
    }
    .eraseToAnyPublisher()
  }
}
