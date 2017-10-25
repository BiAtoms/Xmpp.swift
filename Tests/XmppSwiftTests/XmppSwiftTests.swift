//
//  XmppSwiftTests.swift
//  XmppSwiftTests
//
//  Created by Orkhan Alikhanov on 10/21/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

import XCTest
import SocketSwift
import Dispatch
@testable import XmppSwift

class XmppSwiftTests: XCTestCase {
    
    func testExample() {
        let stream = XmppStream(jid: JID(user: "orkhan", domain: "orkhan-pc"))
        stream.connect(to: "192.168.138.1")
        stream.openNegotiation()
    
        let ex = expectation(description: "sdsd")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            stream.writer.write("</stream:stream>")
//            ex.fulfill()
        }
    
        waitForExpectations(timeout: 10000, handler: nil)
    }
    
    static var allTests = [
        ("testExample", testExample)
    ]
}
