//
//  FirebaseNetworkService.swift
//  FreshNote
//
//  Created by SeokHyun on 11/11/24.
//

import Combine

import FirebaseFirestore
import FirebaseStorage

enum FirebaseNetworkServiceError: Error {
  case invalidData
  case encodingError
  case dataUploadFailed
}

protocol FirebaseNetworkService {
  func getDocument<T: Decodable>(documentPath: String) -> AnyPublisher<T, any Error>
  func getDocuments<T: Decodable>(collectionPath: String) -> AnyPublisher<[T], any Error>
  func setDocument<T: Encodable>(documentPath: String, requestDTO: T, merge: Bool) -> AnyPublisher<Void, any Error>
  func uploadData(path: String, fileName: String, data: Data) -> AnyPublisher<URL, any Error>
  /// storage에서 urlString을 기반인 데이터를 제거합니다.
  func deleteData(urlString: String) -> AnyPublisher<Void, any Error>
  func deleteDocument(documentPath: String) -> AnyPublisher<Void, any Error>
}

final class DefaultFirebaseNetworkService: FirebaseNetworkService {
  private let firestore = Firestore.firestore()
  private let storage = Storage.storage()
  
  func setDocument<T: Encodable>(
    documentPath: String,
    requestDTO: T,
    merge: Bool
  ) -> AnyPublisher<Void, any Error> {
    return Future { [weak self] promise in
      guard let self else { return promise(.failure(CommonError.referenceError)) }
      
      guard let dictionary = try? requestDTO.toDictionary() else {
        return promise(.failure(FirebaseNetworkServiceError.encodingError))
      }
      
      self.firestore.document(documentPath)
        .setData(dictionary, merge: merge) { error in
          if let error = error {
            return promise(.failure(error))
          }
          return promise(.success(()))
        }
    }
    .eraseToAnyPublisher()
  }
  
  func getDocument<T: Decodable>(documentPath: String) -> AnyPublisher<T, any Error> {
    return Future { [weak self] promise in
      guard let self else { return promise(.failure(CommonError.referenceError)) }
      
      self.firestore.document(documentPath).getDocument { (snapshot, error) in
        if let error = error {
          return promise(.failure(error))
        }
        
        guard let dictionary = snapshot?.data() else {
          return promise(.failure(FirebaseNetworkServiceError.invalidData))
        }
        
        do {
          let data = try JSONSerialization.data(withJSONObject: dictionary)
          let decodedData = try JSONDecoder().decode(T.self, from: data)
          return promise(.success(decodedData))
        } catch {
          return promise(.failure(error))
        }
      }
    }
    .eraseToAnyPublisher()
  }
  
  func getDocuments<T: Decodable>(collectionPath: String) -> AnyPublisher<[T], any Error> {
    return Future { [weak self] promise in
      guard let self else { return promise(.failure(CommonError.referenceError)) }
      
      self.firestore.collection(collectionPath).getDocuments { (snapshot, error) in
        if let error = error {
          return promise(.failure(error))
        }
        
        do {
          let decodedDatas: [T] = try snapshot?.documents.compactMap { snapshot in
            let dictionary = snapshot.data()
            let data = try JSONSerialization.data(withJSONObject: dictionary)
            let decodedData = try JSONDecoder().decode(T.self, from: data)
            return decodedData
          } ?? []
          
          return promise(.success(decodedDatas))
        } catch {
          return promise(.failure(error))
        }
      }
    }
    .eraseToAnyPublisher()
  }
  
  func deleteDocument(documentPath: String) -> AnyPublisher<Void, any Error> {
    return Future { [weak self] promise in
      guard let self else { return promise(.failure(CommonError.referenceError)) }
      
      self.firestore.document(documentPath)
        .delete { completion in
          if let error = completion {
            return promise(.failure(error))
          }
          return promise(.success(()))
        }
    }
    .eraseToAnyPublisher()
  }
  
  // MARK: - Firebase Storage
  func uploadData(path: String, fileName: String, data: Data) -> AnyPublisher<URL, any Error> {
    let relativePath = "\(path)/\(fileName)"
    let storageReference = self.storage.reference().child(relativePath)
    let metaData = StorageMetadata()
    metaData.contentType = "image/jpeg"
    
    return Future { promise in
      storageReference.putData(data, metadata: metaData) { (_, error) in
        if let error = error { return promise(.failure(error)) }
        
        storageReference.downloadURL { url, error in
          if let error = error { return promise(.failure(error)) }
          
          guard let url = url else { return promise(.failure(FirebaseNetworkServiceError.dataUploadFailed)) }
          return promise(.success(url))
        }
      }
    }
    .eraseToAnyPublisher()
  }
  
  func deleteData(urlString: String) -> AnyPublisher<Void, any Error> {
    return Future { [weak self] promise in
      guard let self else { return promise(.failure(CommonError.referenceError)) }
      
      self.storage.reference(forURL: urlString).delete { error in
        if let error = error { return promise(.failure(error)) }
        return promise(.success(()))
      }
    }
    .eraseToAnyPublisher()
  }
}
