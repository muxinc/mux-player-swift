//
//  ContentKeySessionDelegateTests.swift
//
//
//  Created by Emily Dixon on 5/7/24.
//

import Foundation
import XCTest
@testable import MuxPlayerSwift

class ContentKeySessionDelegateTests : XCTestCase {
    
//    var sessionDelegate: ContentKeySessionDelegate<FairPlayStreamingSessionManager>!
    
    override func setUp() async throws {
        
    }
    
    func testParsePlaybackId() throws {
       let fakeKeyUri = "skd://fake.domain/?playbackId=12345&token=unrelated-to-test"
        
    }
}
