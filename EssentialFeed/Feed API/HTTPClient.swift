//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by koushik V on 17/02/2024.
//

import Foundation

public enum HTTPClientResponse {
    case success(Data,HTTPURLResponse)
    case failure(Error)
}
public protocol HTTPClient {
    func get(from url:URL, completion: @escaping(HTTPClientResponse)->Void)
}
