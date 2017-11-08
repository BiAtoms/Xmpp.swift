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
    
    let stream = XmppStream(jid: XmppJID(user: "orkhan", domain: "orkhan-pc", resource: "test"))
    
    func testExample() {
        stream.send(element: XmlElement(name: "hey"))
        stream.send(element: XmlElement(name: "hey2"))
        stream.send(element: XmlElement(name: "hey3"))
        stream.connect(to: "192.168.138.1")
        stream.openNegotiation()
        
        let ex = expectation(description: "sdsd")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.stream.authenticate(password: "orkhan12")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                
                let p = XmppPresence(type: .available)
                self.stream.send(element: p)
            }
        }
        
        waitForExpectations(timeout: 10000, handler: nil)
    }
    
    static var allTests = [
        ("testExample", testExample)
    ]
}
