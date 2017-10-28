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

public struct XmppIQType: RawStringRepresentable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    
    static let set = XmppIQType(rawValue: "set")
    static let get = XmppIQType(rawValue: "get")
}
