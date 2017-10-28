//
//  XmppStanza.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/28/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

import Foundation

public protocol RawStringRepresentable: RawRepresentable where RawValue == String {}

open class XmppStanza<Type: RawStringRepresentable>: XmlElement {
    open class var stanza: String { return "" }
    public convenience init(type: Type, from: XmppJID? = nil, to: XmppJID? = nil, id: String? = nil) {
        self.init(name: Swift.type(of: self).stanza)
        self.type = type
        self.from = from
        self.to = to
        self.id = id
    }
    
    open var type: Type? {
        get {
            guard let s = attributes["type"] else {
                return nil
            }
            return Type(rawValue: s)
        }
        set {
            attributes["type"] = newValue?.rawValue
        }
    }
    
    open var id: String? {
        get {
            return attributes["id"]
        }
        set {
            attributes["id"] = newValue
        }
    }
    
    open var from: XmppJID? {
        get {
            return XmppJID(parsing: attributes["from"])
        }
        set {
            attributes["from"] = newValue?.full
        }
    }
    
    open var to: XmppJID? {
        get {
            return XmppJID(parsing: attributes["to"])
        }
        set {
            attributes["to"] = newValue?.full
        }
    }
}
