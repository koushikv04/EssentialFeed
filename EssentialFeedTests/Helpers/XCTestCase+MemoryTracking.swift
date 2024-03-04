//
//  XCTestCase+MemoryTracking.swift
//  EssentialFeedTests
//
//  Created by koushik V on 28/02/2024.
//

import Foundation
import XCTest

extension XCTestCase {
    func trackMemoryLeak(_ instance:AnyObject,file:StaticString = #file, line:UInt = #line) {
        addTeardownBlock {[weak instance] in
            XCTAssertNil(instance,"instance should have been deallocated. potential memory leak")
        }
    }
}
