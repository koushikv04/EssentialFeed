//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by koushik V on 22/02/2024.
//

import Foundation
import XCTest
import EssentialFeed


class URLSessionHTTPClientTests:XCTestCase {
    
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        super.tearDown()
        
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromURL_observerequest() {
        let url = anyURL()
        let exp = self.expectation(description: "wait for expectation")
        URLProtocolStub.observeRequests { urlRequest in
            XCTAssertEqual(urlRequest.url, url)
            XCTAssertEqual(urlRequest.httpMethod, "GET")
            exp.fulfill()
        }
        makeSUT().get(from: url) { _ in
            
        }
        wait(for: [exp], timeout: 1.0)

    }
    func test_getFromURL_failsOnRequestError() {
        let requestError = anynsError()
        let receivedError = resultErrorfor(data: nil, urlResponse: nil, error: requestError) as? NSError
        XCTAssertEqual(receivedError?.domain, requestError.domain)
        XCTAssertEqual(receivedError?.code, requestError.code)
    }
    
    func test_getFromURL_failsOnallInvalidRepresentationCases() {
        XCTAssertNotNil(resultErrorfor(data: nil, urlResponse: nil, error: nil))
        XCTAssertNotNil(resultErrorfor(data: nil, urlResponse: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorfor(data: anyData(), urlResponse: nil, error: nil))
        XCTAssertNotNil(resultErrorfor(data: anyData(), urlResponse: nil, error: anynsError()))
        XCTAssertNotNil(resultErrorfor(data: nil, urlResponse: nonHTTPURLResponse(), error: anynsError()))
        XCTAssertNotNil(resultErrorfor(data: nil, urlResponse: anyHTTPURLResponse(), error: anynsError()))
        XCTAssertNotNil(resultErrorfor(data: anyData(), urlResponse: anyHTTPURLResponse(), error: anynsError()))
        XCTAssertNotNil(resultErrorfor(data: anyData(), urlResponse: nonHTTPURLResponse(), error: anynsError()))
        XCTAssertNotNil(resultErrorfor(data: anyData(), urlResponse: nonHTTPURLResponse(), error: nil))

    }
    
    func test_getfromURL_succeedsOnHTTPURLResponsewithData() {
        let anyData = anyData()
        let anyResponse = anyHTTPURLResponse()
        let receivedValues = resultValuesfor(data: anyData, urlResponse: anyResponse, error: nil)
        XCTAssertEqual(receivedValues?.data, anyData)
        XCTAssertEqual(receivedValues?.response.url, anyResponse.url)
        XCTAssertEqual(receivedValues?.response.statusCode, anyResponse.statusCode)
    }
    
    func test_getfromURL_succeedsOnEmptyDataHTTPURLResponsewithNilData() {
        let anyResponse = anyHTTPURLResponse()

        let receivedValues = resultValuesfor(data: nil, urlResponse: anyResponse, error: nil)
        let emptyData = Data()
        XCTAssertEqual(receivedValues?.data, emptyData)
        XCTAssertEqual(receivedValues?.response.url, anyResponse.url)
        XCTAssertEqual(receivedValues?.response.statusCode, anyResponse.statusCode)
    }
    
    //MARK:- helpers
    
    private func makeSUT(file:StaticString = #file, line:UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient()
        trackMemoryLeak(sut,file: file, line: line)
        return sut
    }
    
    private func anyData() -> Data {
        return Data("anydata".utf8)
    }
    
    private func anynsError() -> NSError {
        return NSError(domain: "some error", code: 500)
    }
    
    private func nonHTTPURLResponse() -> URLResponse {
        return  URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    private func resultErrorfor(data:Data?,urlResponse:URLResponse?,error:Error?,file:StaticString = #file, line:UInt = #line) -> Error? {
        let receivedResult = resultFor(data: data, urlResponse: urlResponse, error: error,file: file, line: line)
        switch receivedResult {
        case let .failure(error):
            return error
        default:
            XCTFail("unexpected failure but got result \(receivedResult)",file: file,line: line)
            return nil
        }
    }
    
    private func resultValuesfor(data:Data?,urlResponse:URLResponse?,error:Error?,file:StaticString = #file, line:UInt = #line) -> (data:Data,response:HTTPURLResponse)? {
        let receivedResult = resultFor(data: data, urlResponse: urlResponse, error: error,file: file, line: line)
        switch receivedResult {
        case let .success(data, response):
            return(data,response)
        default:
            XCTFail("unexpected failure but got result \(receivedResult)",file: file,line: line)
            return nil
        }
    }
    private func resultFor(data:Data?,urlResponse:URLResponse?,error:Error?,file:StaticString = #file, line:UInt = #line) -> HTTPClientResponse {
        let url = anyURL()
        URLProtocolStub.stub(data: data,response: urlResponse, error:error)
        let sut = makeSUT(file: file, line:line)
        let exp = self.expectation(description: "wait for completion")
        var receivedResult:HTTPClientResponse!
        sut.get(from:url) { result in
            receivedResult = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return receivedResult
    }
    private func anyURL() -> URL {
        return URL(string:"https://any-url.com")!
    }
    
    private class URLProtocolStub:URLProtocol {
        private static var stub:Stub?
        private static var requestObserver:((URLRequest)->Void)?
        
        private struct Stub {
            var data:Data?
            var response:URLResponse?
            var error:Error?
        }
        
        static func observeRequests(observer: @escaping (URLRequest)->Void) {
            URLProtocolStub.requestObserver = observer
        }
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)

        }
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil

        }
        static func stub(data:Data?, response:URLResponse?, error:Error?) {
            stub = Stub(data: data,response: response, error: error)
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            URLProtocolStub.requestObserver?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response,cacheStoragePolicy: .notAllowed)
            }
            
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {
            
        }
    
    }
}
