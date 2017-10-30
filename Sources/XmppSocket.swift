//
//  XmppSocket.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/29/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

import Foundation
import SocketSwift

public protocol XmppSocketDelegate: class {
    func socket(_ socket: XmppSocket, didDisconnect error: Error?)
//    func socket(_ socket: XmppSocket, didConnect )
}

open class XmppSocket: Socket {
    
    open weak var delegate: XmppSocketDelegate?
    
    open override func read(_ buffer: UnsafeMutableRawPointer, bufferSize: Int) throws -> Int {
        return try checkingDisconnection { try super.read(buffer, bufferSize: bufferSize) }
    }
    
    open override func write(_ buffer: UnsafeRawPointer, length: Int) throws {
        try checkingDisconnection { try super.write(buffer, length: length) }
    }
    
    private func checkingDisconnection<T>(_ block: () throws -> T) rethrows -> T {
        do {
            return try block()
        } catch {
            //TODO: rethink this
            if (error as! Socket.Error).errno != EWOULDBLOCK { //not timeout
                delegate?.socket(self, didDisconnect: error)
            }
            throw error
        }
    }
}

extension XmppSocket {
    open class func resolveAndConnect(to domain: String, queue: DispatchQueue, completion: (XmppSocket?)-> Void) {
        //resolve the host through SRV at queue
    }
    
    open class func connect(to host: String, port: Port, queue: DispatchQueue, completion: (XmppSocket?)-> Void) {
        //resolve the host through SRV at queue
    }
}
