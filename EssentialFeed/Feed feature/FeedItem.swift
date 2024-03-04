//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Kaushik on 04/02/2024.
//

import Foundation

public struct FeedItem: Equatable {
    public var id : UUID
    public var description:String?
    public var location:String?
    public var imageURL:URL
    
    public init(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.imageURL = imageURL
    }
}
