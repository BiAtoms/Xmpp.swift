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
    open let queue = DispatchQueue(label: "com.biatoms.xmpp-swift.reader")
    private var stream: Stream
    open weak var delegate: XmppReaderDelegate?
    
    public init(stream: XmppReader.Stream) {
        self.stream = stream
    }
    
    public convenience init(socket: XmppSocket) {
        self.init(stream: XmppReader.Stream(socket: socket))
    }
    

    private var xmlParser: XmlParser?
    func read() {
        queue.async {
            // We have to create new XmlParser. Otherwise, parser won't parse after an abort
            let xmlParser = XmlParser(stream: self.stream)
            xmlParser.delegate = self
            self.xmlParser = xmlParser
            
            // This method calls `XmppInputStream.read()` which calls `XmppSocket.wait(.read)`
            // then `XmppSocket.read()` internally.

            // `XmppInputStream.read()` will return 0 when `XmppSocket.wait()` or `XmppSocket.read()`
            // throws. In other words, `XMLParser` will always fail with an error that byte stream is
            // finished but the xml document tree is incomplete.
            
            // So, the return value will always be `false` and we ignore it.
            // Disconnection/timeout will reported by `XmppSocket`
            self.stream.stopReading = false
            _ = xmlParser.parse()
        }
    }
    
    func abort() {
        stream.stopReading = true
        xmlParser?.abortParsing()
        xmlParser = nil
        openElements = 0
        openStreamElements = 0
        currentStreamElement = nil
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
        open let socket: XmppSocket
        internal var stopReading = false
        
        public init(socket: XmppSocket) {
            self.socket = socket
            super.init(data: Data())
        }
        
        
        // Here is the deal. When we need to start tls handshake we must not call `socket.read()`.
        // Therefore, we use `socket.wait()` to wait until data is available then check if we are
        // allowed to read (through variable `stopReading`) then we call `socket.read()`. if we call
        // `socket.read()` directly (without `socket.wait`)  it will read the tls handshake as well.
        // So the `stopReading` variable is needed to prevent reading handshake bytes.

        override open func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
            // We will wait until data is available to read, or error happens
            // on error, `while let` loop will stop execution.
            while let available = try? socket.wait(for: .read, timeout: 0.2), !stopReading {
                guard available else { continue } // timeout happend, try again
                
                let n = try? socket.read(buffer, size: len)
                //TODO: use a flag if document header is expected, then wipe it
                wipeDocumentHeaderIfNeeded(buffer, n ?? 0)
                return n ?? 0
            }
            
            return 0
        }
        
        
        // reading document header (<?xml version='1.0'?>) second time (e.g sent after second openNegotiation())
        // causes error on parser. we replace the header with ignored whitespace (e.x " ")
        //
        // the parser error could not be prevented and once error happend, it means the socket
        // has alreay gave some portion (maybe all of) the buffered bytes which was part of the document
        // TODO: optimize/workaround this
        // Maybe, we can abort parsing and restart it when there is possibility of having doc header
        
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
