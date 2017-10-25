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
        return n ?? -1
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
