//
//  Stream.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/21/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

import Foundation

//TODO: use serial queues to ensure correct order of sending/receiving things
open class XmppStream {
    open let jid: JID
    open let keepAliveBytes: [Byte] = " ".bytes
    open let queue = DispatchQueue(label: "com.biatoms.xmpp-swift.stream")// + UUID().uuidString)
    
    open var isConnectionNew = true
    open var socket: Socket
    open var reader: XmppReader
    open var writer: XmppWriter
    open private(set) var state: State = .disconnected
    public init(jid: JID) {
        self.jid = jid
        
        
        //dump
        
        self.socket = Socket(with: 0)
        self.reader = XmppReader(socket: socket)
        self.writer = XmppWriter(socket: socket)
    }
    
    open func connect(to host: String, port: Port = 5222) {
        queue.async {
            do {
                self.socket = try Socket(.inet, type: .stream, protocol: .tcp)
                try self.socket.connect(port: port, address: host)
                self.state = .connected
                self.reader = XmppReader(socket: self.socket)
                self.writer = XmppWriter(socket: self.socket)
                
                self.reader.delegate = self
                self.writer.delegate = self
                self.reader.read()
            } catch {
                print("failed to connect", error)
            }
        }
    }
    
    open func openNegotiation() {
        queue.async {
            if self.isConnectionNew {
                self.writer.write("<?xml version='1.0'?>")
                self.isConnectionNew = false
            }
            
            let s = """
            <stream:stream
            to='\(self.jid.domain)'
            version='1.0'
            xml:lang='en'
            xmlns='jabber:client'
            xmlns:stream='http://etherx.jabber.org/streams'>
            """
            
            self.writer.write(s)
        }
    }
}

extension XmppStream: XmppReaderDelegate {
    public func reader(_ reader: XmppReader, didRead element: XmlElement) {
        queue.async {
            switch element.name {
            case "iq":
                print("")
            case "presence":
                print("")
            case "message":
                print("")
            case "stream:features", "features":
                print("")
            case "stream:error", "error":
                print("")
            default:
                print("received unknown element", element)
            }
        }
    }
}

extension XmppStream: XmppWriterDelegate {
    public func writer(_ writer: XmppWriter, didSend element: XmlElement) {
        queue.async {
            //
        }
    }
}


extension XmppStream {
    public enum State {
        case disconnected
        case connected
    }
}
