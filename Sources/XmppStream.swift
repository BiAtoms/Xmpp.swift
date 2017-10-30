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
    
    open private(set) var socket: XmppSocket
    open private(set) var reader: XmppReader
    open private(set) var writer: XmppWriter
    open private(set) var features: XmppFeatures? //holds <stream:stream> as well. It's parent
    open private(set) var state: State = .disconnected
    open private(set) var isAuthenticated = false
    open var shouldReopenNegotiation = true
    open var authenticator: XmppAuthenticator = XmppPlainAuthenticator()
    open var binder: XmppBinder = XmppDefaultBinder()
    open var sessionStarter: XmppSessionStater = XmppDefaultSessionStarter()
    open let delegate = MulticastDelegate<XmppStreamDelegate>()
    
    public init(jid: XmppJID) {
        self.jid = jid
        
        
        //dump
        
        self.socket = XmppSocket(with: 0)
        self.reader = XmppReader(socket: socket)
        self.writer = XmppWriter(socket: socket)
    }
    
    open func connect(to host: String, port: Port = 5222) {
        queue.async {
            do {
                self.socket = try XmppSocket(.inet, type: .stream, protocol: .tcp)
                self.socket.delegate = self
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
        assert(state == .connected)
        let s = """
        <?xml version='1.0'?>
        <stream:stream
        to='\(jid.domain)'
        version='1.0'
        xml:lang='en'
        xmlns='jabber:client'
        xmlns:stream='http://etherx.jabber.org/streams'>
        """
        
        state = .negotiating
        writer.write(s) { isWritten in
            if !isWritten {
                print("failed to open neogtiation")
            }
        }
    }
    
    open func authenticate(password: String) {
        queue.async {
            assert(self.state == .connected)
            self.state = .authenticating
            self.writer.send(element: self.authenticator.start(jid: self.jid, password: password))
        }
    }
}

extension XmppStream: XmppReaderDelegate {
    public func reader(_ reader: XmppReader, didRead element: XmlElement) {
        queue.async {
            if self.state == .authenticating {
                assert(self.isAuthenticated == false)
                assert(self.features!.supportsAuthenticator(self.authenticator) == true)
                
                switch self.authenticator.handleResponse(element) {
                case .continue(let element):
                    self.writer.send(element: element)
                case .success:
                    print("didAuthenticate")
                    self.state = .connected
                    self.isAuthenticated = true
                    
                    if self.shouldReopenNegotiation {
                        self.openNegotiation()
                    }
                    
                    //self.delegate |> inform success
                case .error(let error):
                    print("didFailAuthenticate", error, element)
                    self.state = .connected
                }
                return
            }
            
            if self.isAuthenticated && element.name == "stream:features" { //we just successfully logged in. try to bind and start session if needed
                assert(self.features != nil) //this should not be nil either
                
                //TODO should we call delegate.didReceive features???
                self.features = XmppFeatures(element)
                
                let features = self.features!
                
                if features.needsBinding {
                    self.state = .binding
                    self.writer.send(element: self.binder.start(jid: self.jid))
                } else {
                    self.state = .connected
                }
                return
            }
            
            if self.state == .binding {
                switch self.binder.handleResponse(element) {
                case .success:
                    print("Bound successfully with element:", element)
                    assert(self.features != nil)
                    let features = self.features!
                    if features.needsSession {
                        self.state = .startingSession
                        self.writer.send(element: self.sessionStarter.start(jid: self.jid))
                    } else {
                        self.state = .connected
                    }
                case .error(let e):
                    print("binding failed with element:", element, e)
                case .continue(let element):
                    self.writer.send(element: element)
                }
                return
            }
            
            if self.state == .startingSession {
                switch self.sessionStarter.handleResponse(element) {
                case .success:
                    print("Started session successfully with element:", element)
                    self.state = .connected
                case .error(let e):
                    print("starting session failed with element:", element, e)
                    self.state = .connected
                case .continue(let element):
                    self.writer.send(element: element)
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
            case "stream:features":
                assert(self.state == .negotiating)
                self.features = XmppFeatures(element)
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
        //
    }
    
    public func writer(_ writer: XmppWriter, didFailToSend element: XmlElement) {
        //
    }
}

extension XmppStream: XmppSocketDelegate {
    public func socket(_ socket: XmppSocket, didDisconnect error: Error?) {
        //TODO: clean & call delegates
        //TODO: in which queue is this called???
        self.state = .disconnected
    }
}

extension XmppStream {
    public struct State: RawRepresentable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        
        static let disconnected = State(rawValue: 0)
        static let negotiating = State(rawValue: 10)
        static let authenticating = State(rawValue: 20)
        static let binding = State(rawValue: 30)
        static let startingSession = State(rawValue: 40)
        static let connected = State(rawValue: 100)
        
    }
}
