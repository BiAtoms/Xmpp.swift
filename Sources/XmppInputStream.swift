//
//  XmppInputStream.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/24/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

import Foundation

open class XmppInputStream: InputStream {
    open let socket: Socket
    open private(set) var numberOfReadBytes: UInt64 = 0
    
    public init(socket: Socket) {
        self.socket = socket
        super.init(data: Data())
    }
    
    override open func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        let n = try? socket.read(buffer, bufferSize: len)
        numberOfReadBytes += UInt64(n ?? 0)
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
