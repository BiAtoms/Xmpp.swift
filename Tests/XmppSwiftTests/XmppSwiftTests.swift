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
    
    let stream = XmppStream(jid: XmppJID(user: "orkhan", domain: "orkhan-pc"))
    
    func testExample() {
        stream.connect(to: "192.168.138.1")
        stream.openNegotiation()
        
        let ex = expectation(description: "sdsd")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.stream.authenticate(password: "orkhan12")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                
                print(self.stream.features!.parent!)
//                let s = "<presence xmlns=\"jabber:client\" to=\"orkhan@orkhan-pc\" from=\"orkhan@orkhan-pc/test\"><status>Available</status></presence>"
                let iq = XmppIQ.init(type: .get, id: .uuid)
                iq.attributes["to"] = "orkhan-pc"
                let query = XmlElement(name: "query", xmlns: "http://jabber.org/protocol/disco#items")
//                query.attributes["node"] = "http://jabber.org/protocol/commands"
                iq.children.append(query)
                
                
                self.stream.writer.send(element: iq)
            }
//            //            stream.writer.write("</stream:stream>")
//            //            ex.fulfill()
        }
        
        waitForExpectations(timeout: 10000, handler: nil)
    }
    
    static var allTests = [
        ("testExample", testExample)
    ]
}
