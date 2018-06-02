//
//  XmppPresence.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/25/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//


open class XmppPresence: XmppStanza<XmppPresenceType> {
    override open class var stanza: String { return "presence" }
    
    public enum ShowType: String {
        case chat
        case away
        case extendedAway = "xa"
        case doNotDisturb = "dnd"
    }
    
    open var show: ShowType? {
        get {
            guard let text = element(named: "show")?.text else {
                return type == .available ? .chat : nil
            }
            return ShowType(rawValue: text)
        }
        set(v) {
            let t = v == .chat ? nil : v?.rawValue // default is .chat anyways
            setElementText(named: "show", text: t)
        }
    }
    
    open var status: String? {
        get {
            return element(named: "status")?.text
        }
        set {
            setElementText(named: "status", text: newValue)
        }
    }
    
    
    /// Never returns nil
    open override var type: XmppPresenceType! {
        get {
            return super.type ?? .available
        }
        set(v) {
            super.type = v == .available ? nil : v // default is .available anyways
        }
    }
    
    
    
    private func setElementText(named name: String, text: String?) {
        if let text = text {
            if let e = element(named: name) {
                e.text = text
            } else {
                children.append(XmlElement(name: name, text: text))
            }
        } else {
            guard let i = children.index(where: { $0.name == name }) else {
                return
            }
            children.remove(at: i)
        }
    }
}

public enum XmppPresenceType: String, RawStringRepresentable {
    case error
    case subscribe
    case subscribed
    case unavailable
    case unsubscribe
    case unsubscribed
    
    case available
}
