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
    func writer(_ writer: XmppWriter, didFailToSend element: XmlElement)
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
        write(element.xml) { isWritten in
            if isWritten {
                self.delegate?.writer(self, didSend: element)
            } else {
                self.delegate?.writer(self, didFailToSend: element)
            }
        }
    }
    
    open func write(_ string: String, completion: @escaping (Bool) -> Void) {
        queue.async {
            do {
                let bytes = string.bytes
                self.numberOfWrittenBytes += UInt64(bytes.count)
                try self.socket.write(bytes)
                completion(true)
            } catch {
                completion(false)
            }
        }
    }
}
