//
//  Stream.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/21/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

import Foundation

public protocol XmppStreamDelegate {
    // TODO: think about adding willReceive...,
    // TODO: add , and willSend...
    func stream(_ stream: XmppStream, didReceiveMessage message: XmppMessage)
    func stream(_ stream: XmppStream, didReceivePresence presence: XmppPresence)
    func stream(_ stream: XmppStream, didReceiveIQ iq: XmppIQ) -> Bool
}

//TODO: use serial queues to ensure correct order of sending/receiving things
open class XmppStream {
    open let jid: XmppJID
    
    open private(set) var socket: XmppSocket
    open private(set) var reader: XmppReader
    open private(set) var features: XmppFeatures? //holds <stream:stream> as well. It's parent
    open private(set) var state: State = .disconnected
    open private(set) var isAuthenticated = false
    open private(set) var numberOfWrittenBytes: UInt64 = 0
    open var shouldReopenNegotiation = true
    open var authenticator: XmppAuthenticator = XmppPlainAuthenticator()
    open var binder: XmppBinder = XmppDefaultBinder()
    open let delegate = MulticastDelegate<XmppStreamDelegate>()
    
    /// A serial queue for connect/send.
    open let queue = DispatchQueue(label: "com.biatoms.xmpp-swift.writer")
    
    public init(jid: XmppJID) {
        self.jid = jid
        
        //dump
        socket = XmppSocket(with: 0)
        reader = XmppReader(socket: socket)
    }
    
    //TODO: make this guy async
    open func connect(to host: String, port: Port = 5222) {
        
        assert(state == .disconnected)
        do {
            socket = try XmppSocket(.inet, type: .stream, protocol: .tcp)
            socket.delegate = self
            try socket.connect(port: port, address: host)
            state = .connected
            reader = XmppReader(socket: socket)
            
            reader.delegate = self
            reader.read() //start listening on incoming data
        } catch {
            print("failed to connect", error)
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
        send(raw: s) { isWritten in
            if !isWritten {
                print("failed to open neogtiation")
            }
        }
    }
    
    open func authenticate(password: String) {
        assert(state == .connected)
        state = .authenticating
        send(element: authenticator.start(jid: jid, password: password))
    }
}

extension XmppStream: XmppReaderDelegate {
    public func reader(_ reader: XmppReader, didRead element: XmlElement) {
        if state == .authenticating {
            assert(isAuthenticated == false)
            assert(features!.supportsAuthenticator(authenticator) == true)
            
            switch authenticator.handleResponse(element) {
            case .continue(let element):
                send(element: element)
            case .success:
                print("didAuthenticate")
                state = .connected
                isAuthenticated = true
                
                if shouldReopenNegotiation {
                    openNegotiation() //called second time
                }
                
            //delegate |> inform success
            case .error(let error):
                print("didFailAuthenticate", error, element)
                state = .connected
            }
            return
        }
        
        if isAuthenticated && element.name == "stream:features" { //we just successfully logged in. try to bind and start session if needed
            assert(state == .negotiating)
            assert(self.features != nil) //this should not be nil either
            
            //TODO should we call delegate.didReceive features???
            self.features = XmppFeatures(element)
            
            let features = self.features!
            
            if features.needsBinding {
                state = .binding
                send(element: binder.start(jid: jid))
            } else {
                state = .connected
            }
            return
        }
        
        if state == .binding {
            switch binder.handleResponse(element) {
            case .success:
                print("Bound successfully with element:", element)
                state = .connected
            case .error(let e):
                print("binding failed with element:", element, e)
            case .continue(let element):
                send(element: element)
            }
            return
        }
        
        switch element.name {
        case "iq":
            let handled = delegate.invokeAndStopIf(true) {
                $0.stream(self, didReceiveIQ: XmppIQ(element))
            }
            
            if !handled {
                //TODO: send back error
            }
            
        case "presence":
            delegate.invoke {
                $0.stream(self, didReceivePresence: XmppPresence(element))
            }
        case "message":
            delegate.invoke {
                $0.stream(self, didReceiveMessage: XmppMessage(element))
            }
        case "stream:features":
            assert(state == .negotiating)
            features = XmppFeatures(element)
            state = .connected
        case "stream:error":
            print("didReceiveError")
        case "stream:stream":
            print("stream is closed")
            //disconnect
            break
        default:
            print("received unknown element", element)
        }
    }
}

extension XmppStream {
    open func send(element: XmlElement) {
        send(raw: element.xml) { isWritten in
            if isWritten {
                //self.delegate?.stream(self, didSend: element)
            } else {
                //self.delegate?.stream(self, didFailToSend: element)
            }
        }
    }
    
    open func send(raw string: String, completion: @escaping (Bool) -> Void) {
        queue.async {
            do {
                let bytes = string.bytes
                try self.socket.write(bytes)
                self.numberOfWrittenBytes += UInt64(bytes.count)
                completion(true)
            } catch {
                completion(false)
            }
        }
    }
}

extension XmppStream: XmppSocketDelegate {
    public func socket(_ socket: XmppSocket, didDisconnect error: Error?) {
        //TODO: clean & call delegates
        //TODO: in which queue is this called???
        guard state != .disconnected else { return }
        
        state = .disconnected
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
        static let connected = State(rawValue: 100)
        
    }
}
