//
//  XmppReader.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/23/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

import Foundation
import Dispatch
import XmlSwift
import SocketSwift

public protocol XmppReaderDelegate: class {
    func reader(_ reader: XmppReader, didRead element: XmlElement)
}

open class XmppReader {
    open let xmlParser: XmlParser
    open let queue = DispatchQueue(label: "com.biatoms.xmpp-swift.reader")
    open weak var delegate: XmppReaderDelegate?
    
    public init(stream: XmppInputStream) {
        xmlParser = XmlParser(stream: stream)
        xmlParser.delegate = self
    }
    
    public convenience init(socket: Socket) {
        self.init(stream: XmppInputStream(socket: socket))
    }
    
    func read() {
        queue.async {
            if !self.xmlParser.parse() {
                print("Failed to parse", self.xmlParser.error as Any)
            }
        }
    }
    
    func abort() {
        self.xmlParser.abortParsing()
        openElements = 0
    }
    
    private var openElements = 0
}

extension XmppReader: XmlParserDelegate {
    public func parser(_ parser: XmlParser, didStartElement elementName: String) {
        openElements += 1
        
        if openElements == 2 { // after <stream:stream>

        }
    }
    
    public func parser(_ parser: XmlParser, didEndElement elementName: String) {
        openElements -= 1
        if openElements == 1 { //only </stream:stream> remains, so we have read an element
            delegate?.reader(self, didRead: parser.document.root!.children.last!)
        } else if openElements == 0 { //finished doc

        }
    }
}
