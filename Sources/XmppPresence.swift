//
//  XmppPresence.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/25/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//


open class XmppPresence: XmppStanza<XmppPresenceType> {
    override open class var stanza: String { return "presence" }
}

public struct XmppPresenceType: RawStringRepresentable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    
    static let available = XmppPresenceType(rawValue: "available")
    static let unavailable = XmppPresenceType(rawValue: "unavailable")
    static let subscribe = XmppPresenceType(rawValue: "subscribe")
    static let unsubscribe = XmppPresenceType(rawValue: "unsubscribe")
}
