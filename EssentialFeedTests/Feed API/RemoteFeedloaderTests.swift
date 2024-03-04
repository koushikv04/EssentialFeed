//
//  RemoteFeedloaderTests.swift
//  EssentialFeedTests
//
//  Created by Kaushik on 05/02/2024.
//

import XCTest
import EssentialFeed

final class RemoteFeedloaderTests: XCTestCase {
    
    func test_init_doesnotRequestDatafromURL() {
        let (_,client) = makeSUT()
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    
    func test_load_requestDatafromURL() {
        let url = URL(string: "https://www.a-url.com")!
        let (sut,client) = makeSUT(url: url)
        
        sut.load{_ in }
        
        XCTAssertEqual(client.requestedURLs,[url])
    }
    
    func test_loadtwice_requestDataTwice() {
        let url = URL(string: "https://www.a-url.com")!
        let (sut,client) = makeSUT(url: url)
        
        sut.load{_ in }
        sut.load{_ in }
        
        XCTAssertEqual(client.requestedURLs,[url,url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut,client) = makeSUT()
        execute(sut, tocompletewith: failure(.connectivity)) {
            let clientError = NSError(domain: "test", code: 0)
            client.complete(with: clientError)
        }
    }
    func test_load_deliversErrorOnNon200httpresponse() {
        let (sut,client) = makeSUT()
        let samples = [199,201,300,400,500]
        samples.enumerated().forEach { index,code in
            execute(sut, tocompletewith: failure(.invalidData)) {
                let json = makeItemsJSON([])
                client.complete(withStatusCode: code,data: json, at: index)
            }
        }
        
    }
    
    func test_load_deliversErrorOn200httpresponseWithInvalidJSON() {
        let (sut,client) = makeSUT()
        execute(sut, tocompletewith: failure(.invalidData)) {
            let invalidJSON = "Invalid JSON".data(using: .utf8)!
            client.complete(withStatusCode: 200,data:invalidJSON)
        }
    }
    
    func test_load_deliversNoItemsOn200httpresponseWithEmptyJSONlist() {
        let (sut,client) = makeSUT()
        execute(sut, tocompletewith: .success([])) {
            let emptyJSONlist = makeItemsJSON([])
            client.complete(withStatusCode: 200,data:emptyJSONlist)
        }
    }
    
    func test_load_deliversItemsOn200httpresponseWithItems() {
        let (sut,client) = makeSUT()
        let item1 = makeItem(id: UUID(), imageURL: URL(string:"https://a-url.com")!)
        let item2 = makeItem(id: UUID(),description: "some description",location: "a location", imageURL: URL(string:"https://another-url.com")!)
        execute(sut, tocompletewith: .success([item1.model,item2.model])) {
            let json = makeItemsJSON([item1.json,item2.json])
            client.complete(withStatusCode: 200,data: json)
        }

    }
    
    func test_load_doesNotReturnIfSUTisdeallocated() {
        let url = URL(string: "https://a-url.com")!
        let client = HTTPClientSpy()
        var sut:RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
        var capturedResults = [RemoteFeedLoader.Result]()

        sut?.load {
            capturedResults.append($0)
        }
        sut = nil

        client.complete(withStatusCode: 200, data: makeItemsJSON([]))
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    //MARK:- helpers
    private func makeSUT(url:URL = URL(string: "https://www.a-url.com")!,file:StaticString = #file, line:UInt = #line) -> (sut:RemoteFeedLoader,client:HTTPClientSpy) {
        let client = HTTPClientSpy()
        let remoteFeedLoader = RemoteFeedLoader(url: url, client: client)
        trackMemoryLeak(remoteFeedLoader,file:file,line:line)
        trackMemoryLeak(client,file:file,line:line)
        return (sut:remoteFeedLoader,client:client)
    }
    
    private func makeItem(id:UUID,description:String?=nil,location:String?=nil,imageURL:URL) -> (model:FeedItem,json:[String:Any]) {
        let item = FeedItem(id: id,description: description,location: location, imageURL: imageURL)
        let itemJSON = [
            "id":item.id.uuidString,
            "description":description,
            "location":location,
            "image":item.imageURL.absoluteString].compactMapValues { $0
            }
        return (item,itemJSON)
    }
    
    private func makeItemsJSON(_ items:[[String:Any]]) -> Data {
        let items = ["items":items]
        return try! JSONSerialization.data(withJSONObject: items)
    }
        
    private func failure(_ error:RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        return .failure(error)
    }
    
    private func execute(_ sut:RemoteFeedLoader, tocompletewith expectedResult:RemoteFeedLoader.Result,action: ()->Void, file:StaticString = #file, line:UInt = #line) {

        let exp = self.expectation(description: "wait for load completion")
        sut.load { receivedResult in
            switch(receivedResult,expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems,expectedItems,file:file,line:line)
            case let (.failure(receivedError as RemoteFeedLoader.Error),.failure(expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError,expectedError,file:file,line:line)
            default:
                XCTFail("Expected result \(expectedResult) but got received result \(receivedResult)",file: file,line: line)
                        
            }
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)

    }
    
    private  class HTTPClientSpy:HTTPClient {
        
        var error:Error?
        var requestedURLs:[URL] {
            return messages.map{$0.url}
        }
        var messages = [(url:URL,completion:(HTTPClientResponse) -> Void)]()
        
        func get(from url: URL, completion: @escaping (HTTPClientResponse) -> Void) {
            messages.append((url,completion))
        }
        
        func complete(with error:Error, at index:Int = 0) {
            messages[index].completion(.failure(error))
        }
        func complete(withStatusCode code: Int, data:Data, at index:Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index],
                                           statusCode: code,
                                           httpVersion: nil,
                                           headerFields: nil)!
            messages[index].completion(.success(data,response))
        }
    }

}
