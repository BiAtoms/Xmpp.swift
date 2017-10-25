//
//  XmppWriter.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/25/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

import Foundation

public protocol XmppWriterDelegate: class {
    func writer(_ writer: XmppWriter, didSend element: XmlElement)
}

open class XmppWriter {
    open let queue = DispatchQueue(label: "com.biatoms.xmpp-swift.writer")
    open weak var delegate: XmppWriterDelegate?
    open let socket: Socket
    open private(set) var numberOfWrittenBytes: UInt64 = 0
    
    public init(socket: Socket) {
        self.socket = socket
    }
    
    open func send(element: XmlElement) {
        queue.async {
            do {
                try self.write(element.xml.bytes)
                self.delegate?.writer(self, didSend: element)
            } catch {
                print("failed to write element", error)
            }
        }
    }
    
    open func write(_ string: String) {
        queue.async {
            do {
                try self.write(string.bytes)
            } catch {
                print("failed to write string", error)
            }
        }
    }
    
    private func write(_ bytes: [Byte]) throws {
        try socket.write(bytes)
        numberOfWrittenBytes += UInt64(bytes.count)
    }
}
