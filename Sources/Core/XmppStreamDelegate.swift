//
//  XmppStreamDelegate.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 11/23/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

public protocol XmppStreamDelegate {
    func streamDidConnect(_ stream: XmppStream)
    func streamDidDisconnect(_ stream: XmppStream)
    func streamDidFailToConnect(_ stream: XmppStream)
    
    func streamDidStartNegotiation(_ stream: XmppStream)
    func streamDidFailToStartNegotiation(_ stream: XmppStream)
    
    func streamDidAuthenticate(_ stream: XmppStream)
    func stream(_ stream: XmppStream, didFailToAuthenticate element: XmlElement)
    
    func stream(_ stream: XmppStream, didReceive message: XmppMessage)
    func stream(_ stream: XmppStream, didReceive presence: XmppPresence)
    func stream(_ stream: XmppStream, didReceive iq: XmppIQ) -> Bool
    func stream(_ stream: XmppStream, didReceive element: XmlElement)
    
    func stream(_ stream: XmppStream, didSend message: XmppMessage)
    func stream(_ stream: XmppStream, didSend presence: XmppPresence)
    func stream(_ stream: XmppStream, didSend iq: XmppIQ)
    func stream(_ stream: XmppStream, didSend element: XmlElement)
    
    func stream(_ stream: XmppStream, didFailToSend message: XmppMessage)
    func stream(_ stream: XmppStream, didFailToSend presence: XmppPresence)
    func stream(_ stream: XmppStream, didFailToSend iq: XmppIQ)
    func stream(_ stream: XmppStream, didFailToSend element: XmlElement)
}

extension XmppStreamDelegate {
    public func streamDidConnect(_ stream: XmppStream) { }
    public func streamDidDisconnect(_ stream: XmppStream) { }
    public func streamDidFailToConnect(_ stream: XmppStream) { }
    
    public func streamDidStartNegotiation(_ stream: XmppStream) { }
    
    public func streamDidFailToStartNegotiation(_ stream: XmppStream) { }
    
    public func streamDidAuthenticate(_ stream: XmppStream) { }
    
    public func stream(_ stream: XmppStream, didFailToAuthenticate element: XmlElement) { }
    
    public func stream(_ stream: XmppStream, didReceive message: XmppMessage) { }
    
    public func stream(_ stream: XmppStream, didReceive presence: XmppPresence) { }
    
    public func stream(_ stream: XmppStream, didReceive iq: XmppIQ) -> Bool { return false }
    
    public func stream(_ stream: XmppStream, didReceive element: XmlElement) { }
    
    public func stream(_ stream: XmppStream, didSend message: XmppMessage) { }
    
    public func stream(_ stream: XmppStream, didSend presence: XmppPresence) { }
    
    public func stream(_ stream: XmppStream, didSend iq: XmppIQ) { }
    
    public func stream(_ stream: XmppStream, didSend element: XmlElement) { }
    
    public func stream(_ stream: XmppStream, didFailToSend message: XmppMessage) { }
    
    public func stream(_ stream: XmppStream, didFailToSend presence: XmppPresence) { }
    
    public func stream(_ stream: XmppStream, didFailToSend iq: XmppIQ) { }
    
    public func stream(_ stream: XmppStream, didFailToSend element: XmlElement) { }
}
