//
//  XmppIQ.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/25/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//


open class XmppIQ: XmlElement {
    
    public init(type: Type, id: String? = nil) {
        super.init(name: "iq")
        
        if let id = id {
            self.attributes["id"] = id
        }
        self.attributes["type"] = type.rawValue
    }
    
    public struct `Type`: RawRepresentable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        
        static let set = Type(rawValue: "set")
        static let get = Type(rawValue: "get")
    }
}
