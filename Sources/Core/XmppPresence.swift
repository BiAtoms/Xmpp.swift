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

public enum XmppPresenceType: String, RawStringRepresentable {
    case error
    case probe
    case subscribe
    case subscribed
    case unavailable
    case unsubscribe
    case unsubscribed
}
