//
//  XmppIQ.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/25/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//



open class XmppIQ: XmppStanza<XmppIQType> {
    override open class var stanza: String { return "iq" }
}

public enum XmppIQType: String, RawStringRepresentable {
    case set
    case get
    case result
    case error
}
