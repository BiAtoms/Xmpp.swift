//
//  XmppAuthenticator.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/23/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

import Foundation

public protocol XmppAuthenticator {
    var mechanism: String { get }
    func start(jid: XmppJID, password: String) -> XmlElement
    func handleResponse(_ element: XmlElement) -> XmppAuthenticatorResult
}

extension XmppAuthenticator {
    public var authElement: XmlElement {
        let auth = XmlElement(name: "auth", xmlns: "urn:ietf:params:xml:ns:xmpp-sasl")
        auth["mechanism"] = mechanism
        return auth
    }
}

public enum XmppAuthenticatorResult {
    case success
    case error
    case `continue`(element: XmlElement)
}
