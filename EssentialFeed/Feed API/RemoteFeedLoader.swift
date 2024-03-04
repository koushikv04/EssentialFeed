//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Kaushik on 05/02/2024.
//

import Foundation



public class RemoteFeedLoader:FeedLoader {
    private let url:URL
    private let client:HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public typealias Result = LoadFeedResult
    
    public init(url:URL,client: HTTPClient) {
        self.url = url
        self.client = client
    }
    public func load(completion : @escaping (Result)->Void) {
        client.get(from: url) {[weak self] response  in
            guard self != nil else {
                return
            }
            switch response {
            case let .success(responseData,response):
                completion(FeedItemsMapper.map(responseData, from: response))
            case .failure(_):
                completion(.failure(Error.connectivity))
            }
        }
    }
    
  
}





