//
//  Stream.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/21/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

import Foundation

public protocol XmppStreamDelegate {
    //ToDo: add willReceive..., didSend.., and willSend...
    func stream(_ stream: XmppStream, didReceiveFeatures features: XmlElement)
    func stream(_ stream: XmppStream, didReceiveError error: XmlElement)
    func stream(_ stream: XmppStream, didReceiveMessage message: XmppMessage)
    func stream(_ stream: XmppStream, didReceivePresence presence: XmppPresence)
    func stream(_ stream: XmppStream, didReceiveIQ iq: XmppIQ)
}

//TODO: use serial queues to ensure correct order of sending/receiving things
open class XmppStream {
    open let jid: XmppJID
    open let keepAliveBytes: [Byte] = " ".bytes
    open let queue = DispatchQueue(label: "com.biatoms.xmpp-swift.stream")// + UUID().uuidString)
    
    open private(set) var isConnectionNew = true
    open private(set) var socket: Socket
    open private(set) var reader: XmppReader
    open private(set) var writer: XmppWriter
    open private(set) var features: XmlElement? //holds <stream:stream> as well. It's parent
    open private(set) var state: State = .disconnected
    open var authenticator: XmppAuthenticator?
    open let delegate = MulticastDelegate<XmppStreamDelegate>()
    
    public init(jid: XmppJID) {
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
            
            self.state = .negotiating
            self.writer.write(s)
        }
    }
    
    open func authenticate(with authenticator: XmppAuthenticator, password: String) {
        queue.async {
            assert(self.state == .connected)
            self.state = .authenticating
            self.authenticator = authenticator
            self.writer.send(element: authenticator.start(jid: self.jid, password: password))
        }
    }
}

extension XmppStream: XmppReaderDelegate {
    public func reader(_ reader: XmppReader, didRead element: XmlElement) {
        queue.async {
            if self.state == .authenticating {
                assert(self.authenticator != nil)
                
                switch self.authenticator!.handleResponse(element) {
                case .continue(let element):
                    self.writer.send(element: element)
                case .success:
                    print("didAuthenticate")
                    self.state = .connected
                    self.authenticator = nil
                    //self.delegate |> inform success
                case .error(let error):
                    print("didFailAuthenticate", error)
                    self.authenticator = nil
                }
                return
            }
            
            switch element.name {
            case "iq":
                print("didReceiveIQ")
            case "presence":
                print("didReceivePresence")
            case "message":
                print("didReceiveMessage")
            case "stream:features", "features":
                assert(self.state == .negotiating)
                self.features = element
                print("didReceiveFeatures")
                self.delegate |> {
                    $0.stream(self, didReceiveFeatures: element)
                }
                self.state = .connected
            case "stream:error", "error":
                print("didReceiveError")
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
    public struct State: RawRepresentable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        
        static let disconnected = State(rawValue: 0)
        static let negotiating = State(rawValue: 10)
        static let authenticating = State(rawValue: 20)
        static let connected = State(rawValue: 100)
        
    }
}
