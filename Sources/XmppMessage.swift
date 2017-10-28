//
//  XmppMessage.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/25/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//


open class XmppMessage: XmppStanza<XmppMessageType> {
    override open class var stanza: String { return "message" }
}

public struct XmppMessageType: RawStringRepresentable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    
    static let chat = XmppMessageType(rawValue: "chat")
}
