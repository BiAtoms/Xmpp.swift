//
//  XmppReader.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/23/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

import Foundation
import XmlSwift

public protocol XmppReaderDelegate: class {
    func reader(_ reader: XmppReader, didRead element: XmlElement)
}

open class XmppReader {
    open let xmlParser: XmlParser
    open let queue = DispatchQueue(label: "com.biatoms.xmpp-swift.reader")
    open weak var delegate: XmppReaderDelegate?
    
    public init(stream: XmppReader.Stream) {
        xmlParser = XmlParser(stream: stream)
        xmlParser.delegate = self
    }
    
    public convenience init(socket: Socket) {
        self.init(stream: XmppReader.Stream(socket: socket))
    }
    
    func read() {
        queue.async {
            // This method calls `XmppInputStream.read()` which calls `XmppSocket.read()` internally
            // The `XmppSocket.read()` will block until disconnection (or timeout, if specified)

            // `XmppInputStream.read()` will return 0 when `XmppSocket.read()` throws.
            // So that, the `XMLParser` will always fail with an error that stream is finished
            // but the document is incomplete.
            
            // So, the return value will always be `false` and we ignore it.
            // Disconnection/timeout will reported by `XmppSocket`
            _ = self.xmlParser.parse()
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


extension XmppReader {
    open class Stream: InputStream {
        open let socket: Socket
        open private(set) var numberOfReadBytes: UInt64 = 0
        
        public init(socket: Socket) {
            self.socket = socket
            super.init(data: Data())
        }
        
        override open func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
            let n = try? socket.read(buffer, bufferSize: len)
            numberOfReadBytes += UInt64(n ?? 0)
            //TODO: use a flag if document header is expected, then wipe it
            wipeDocumentHeaderIfNeeded(buffer, len)
            return n ?? -1
        }
        
        
        // reading document header (<?xml version='1.0'?>) second time (e.g sent after second openNegotiation())
        // causes error on parser. we replace the header with ignored whitespace (e.x " ")
        //
        // the parser error could not be prevented and once error happend, it means the socket
        // has alreay gave some portion (maybe all of) the buffered bytes which was part of the document
        // TODO: optimize/workaround this
        
        func wipeDocumentHeaderIfNeeded(_ buffer: UnsafeMutablePointer<UInt8>, _ len: Int) {
            let data = Data(bytesNoCopy: buffer, count: len, deallocator: .none)
            let s = String(data: data, encoding: .utf8)!
            if let r = s.range(of: "\\<\\?xml .*\\?\\>", options: .regularExpression, range: nil, locale: nil) {
                let b = UnsafeMutableBufferPointer(start: buffer, count: len)
                for i in r.lowerBound.encodedOffset..<r.upperBound.encodedOffset {
                    b[i] = 32 //" "
                }
            }
        }
        
        override open var hasBytesAvailable: Bool {
            fatalError("Should not be called")
        }
        
        open override func open() {
            //opened
        }
        
        open override func close() {
            //closed
        }
        
        open override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoopMode) {
            fatalError("Should not reach here")
        }
        
        open override func remove(from aRunLoop: RunLoop, forMode mode: RunLoopMode) {
            fatalError("Should not reach here")
        }
        
        
        open override var streamStatus: Stream.Status {
            fatalError("Should not reach here")
        }
        
        open override var streamError: Error?  {
            fatalError("Should not reach here")
        }
        override open func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool {
            fatalError("Should not reach here")
        }
    }
}
