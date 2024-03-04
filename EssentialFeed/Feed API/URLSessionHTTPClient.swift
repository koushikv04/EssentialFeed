//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by koushik V on 28/02/2024.
//

import Foundation
public class URLSessionHTTPClient:HTTPClient {
    private let httpSession:URLSession
    
    public init(urlSession: URLSession = .shared) {
        self.httpSession = urlSession
    }
    
    private struct unexpectedValuesRepresentationError:Error {}
    
    public func get(from url:URL, completion:@escaping(HTTPClientResponse)->Void) {
        httpSession.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse{
                completion(.success(data, response))
            } else {
                completion(.failure(unexpectedValuesRepresentationError()))
            }
        }.resume()
    }
}
