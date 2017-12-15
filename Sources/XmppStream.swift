//
//  Stream.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/21/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

import Foundation
import SocketSwift

open class XmppStream {
    open let jid: XmppJID
    
    open private(set) var socket: XmppSocket
    open private(set) var reader: XmppReader
    open private(set) var features: XmppFeatures? //holds <stream:stream> as well. It's parent
    open private(set) var state: State = .disconnected
    open private(set) var isAuthenticated = false
    open var isTlsPreffered = true
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
    
    open func connect(to host: String? = nil, port: Port = 5222) {
        queue.async {
            assert(self.state == .disconnected)
            self.features = nil
            self.isAuthenticated = false
            let records = { () -> [XmppSrvResolver.Record] in
                if let host = host {
                    return [XmppSrvResolver.Record(priority: 0, weight: 0, port: port, target: host)]
                } else {
                    let fallback = XmppSrvResolver.Record(priority: .max, weight: 0, port: 5222, target: self.jid.domain)
                    return (XmppSrvResolver.resolve(domain: self.jid.domain, timeout: 5) ?? []) + [fallback]
                }
            }().sorted { $0.priority == $1.priority ? $0.weight > $1.weight : $0.priority < $1.priority}
        
            do {
                self.socket = try XmppSocket(.inet, type: .stream, protocol: .tcp)
                
                for (i, r) in records.enumerated() {
                    do {
                        let address = try self.socket.addresses(for: r.target, port: r.port).first!
                        try self.socket.connect(address: address)
                        break
                    } catch {
                        if i == records.count - 1 {
                            throw error //call didFailToConnect
                        }
                        //will try next result
                    }
                }
            } catch {
                self.delegate.invoke {
                    $0.streamDidFailToConnect(self)
                }
            }
            
            self.reader = XmppReader(socket: self.socket)
            self.reader.delegate = self
            self.reader.read() //start listening on incoming data, runs on a separate queue.
            self.socket.delegate = self
            self.state = .connected
            self.delegate.invoke {
                $0.streamDidConnect(self)
            }
            self.openNegotiation() //first time
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
            if isWritten {
                self.delegate.invoke {
                    $0.streamDidStartNegotiation(self)
                }
            } else {
                self.delegate.invoke {
                    $0.streamDidFailToStartNegotiation(self)
                }
            }
        }
    }
    
    open func authenticate(password: String) {
        assert(state == .connected)
        state = .authenticating
        send(element: authenticator.start(jid: jid, password: password))
    }
    
    open func disconnect() {
        state = .disconnected
        delegate.invoke {
            $0.streamDidDisconnect(self)
        }

    }
}

extension XmppStream: XmppReaderDelegate {
    public func reader(_ reader: XmppReader, didRead element: XmlElement) {
        if state == .startingTls {
            assert(element.name == "proceed") //server must respond with proceed
            
            queue.async {
                self.reader.abort() //don't read tls handshake
                do {
                    try self.socket.startTls(TLS.Configuration(peer: self.jid.domain))
                } catch {
                    //TODO: disconnect
                    print("socket.startTls failed", error)
                }
                self.reader.read() //continue reading with secure connection
                self.state = .connected
                self.openNegotiation() //restart stream
            }
            
            return
        }
        
        if state == .authenticating {
            assert(isAuthenticated == false)
            assert(features!.supportsAuthenticator(authenticator) == true)
            
            switch authenticator.handleResponse(element) {
            case .continue(let element):
                send(element: element)
            case .success:
                state = .connected
                isAuthenticated = true
                
                delegate.invoke {
                    $0.streamDidAuthenticate(self)
                }
                
                openNegotiation()
            case .error:
                delegate.invoke {
                    $0.stream(self, didFailToAuthenticate: element)
                }
                state = .connected
            }
            return
        }
        
        if isAuthenticated && element.name == "stream:features" {
            assert(state == .negotiating)
            assert(self.features != nil) //this should not be nil either
            
            //TODO should we call delegate.didReceive features???
            self.features = XmppFeatures(element)
            
            state = .binding
            send(element: binder.start(jid: jid))
            return
        }
        
        if state == .binding {
            switch binder.handleResponse(element) {
            case .success:
//                print("Bound successfully with element:", element)
                state = .connected
            case .error:
//                print("binding failed with element:", element)
                disconnect()
                break
            case .continue(let element):
                send(element: element)
            }
            return
        }
        
        switch element.name {
        case "iq":
            let handled = delegate.invokeAndStopIf(true) {
                $0.stream(self, didReceive: XmppIQ(element))
            }
            
            if !handled {
                //TODO: send back error
            }
            
        case "presence":
            delegate.invoke {
                $0.stream(self, didReceive: XmppPresence(element))
            }
        case "message":
            delegate.invoke {
                $0.stream(self, didReceive: XmppMessage(element))
            }
        case "stream:features":
            assert(state == .negotiating)
            features = XmppFeatures(element)
            if features!.requiresTls  || (features!.supportsTls && isTlsPreffered) {
                state = .startingTls
                send(element: XmlElement(name:"starttls", xmlns: "urn:ietf:params:xml:ns:xmpp-tls"))
            } else {
                state = .connected
            }
        case "stream:error":
            print("didReceiveError")
        case "stream:stream":
            print("stream is closed")
            //disconnect
            break
        default:
            delegate.invoke {
                $0.stream(self, didReceive: element)
            }
        }
    }
}

extension XmppStream {
    open func send(element: XmlElement) {
        send(raw: element.xml) { isWritten in
            if isWritten {
                switch element.name {
                case "message":
                    self.delegate.invoke {
                        $0.stream(self, didSend: XmppMessage(element))
                    }
                case "presence":
                    self.delegate.invoke {
                        $0.stream(self, didSend: XmppPresence(element))
                    }
                case "iq":
                    self.delegate.invoke {
                        $0.stream(self, didSend: XmppIQ(element))
                    }
                default:
                    self.delegate.invoke {
                        $0.stream(self, didSend: element)
                    }
                }
            } else {
                switch element.name {
                case "message":
                    self.delegate.invoke {
                        $0.stream(self, didFailToSend: XmppMessage(element))
                    }
                case "presence":
                    self.delegate.invoke {
                        $0.stream(self, didFailToSend: XmppPresence(element))
                    }
                case "iq":
                    self.delegate.invoke {
                        $0.stream(self, didFailToSend: XmppIQ(element))
                    }
                default:
                    self.delegate.invoke {
                        $0.stream(self, didFailToSend: element)
                    }
                }
            }
        }
    }
    
    open func send(raw string: String, completion: @escaping (Bool) -> Void) {
        queue.async {
            do {
                let bytes = string.bytes
                try self.socket.write(bytes)
                completion(true)
            } catch {
                completion(false)
            }
        }
    }
}

extension XmppStream: XmppSocketDelegate {
    public func socket(_ socket: XmppSocket, didDisconnect error: Error?) {
        guard state != .disconnected else { return }
        // Calling `disconnect()` may result in calling this method (`didDisconnect`)
        // but since we have `guard` above, we won't call `disconnect()` again
        disconnect()
    }
}

extension XmppStream {
    public struct State: RawRepresentable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        
        static let disconnected = State(rawValue: 0)
        static let negotiating = State(rawValue: 10)
        static let startingTls = State(rawValue: 15)
        static let authenticating = State(rawValue: 20)
        static let binding = State(rawValue: 30)
        static let connected = State(rawValue: 100)
    }
}
