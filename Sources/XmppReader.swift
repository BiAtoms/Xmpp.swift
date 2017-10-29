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
    
    //TODO: re-think this. it should be simple
    fileprivate var openElements = 0
    fileprivate var openStreamElements = 0
    fileprivate var currentStreamElement: XmlElement!
}

extension XmppReader: XmlParserDelegate {
    public func parser(_ parser: XmlParser, didStartElement elementName: String) {
        if elementName != "stream:stream" {
            openElements += 1
        } else {
            openStreamElements += 1
            func rec(_ i: Int, e: XmlElement) -> XmlElement {
                if i == 1 {
                    return e
                }
                
                return rec(i - 1, e: e.children.last!)
            }
            
            currentStreamElement = rec(openStreamElements, e: parser.document.root!)
        }
    }
    
    public func parser(_ parser: XmlParser, didEndElement elementName: String) {
        openElements -= 1
        if openElements == 0 {
            delegate?.reader(self, didRead: currentStreamElement.children.last!)
        } else if openElements < 0 {
            assert(elementName == "stream:stream")
            delegate?.reader(self, didRead: currentStreamElement)
        }
    }
}
