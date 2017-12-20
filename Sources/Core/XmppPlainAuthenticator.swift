//
//  XmppPlainAuthenticator.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/23/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

import Foundation

open class XmppPlainAuthenticator: XmppAuthenticator {
    open var mechanism: String { return "PLAIN" }
    
    open func start(jid: XmppJID, password: String) -> XmlElement {
        let auth = authElement
        auth.text = "\0\(jid.user)\0\(password)".base64Encoded
        return auth
    }
    
    open func handleResponse(_ element: XmlElement) -> XmppAuthenticatorResult {
        return element.name == "success" ? .success : .error
    }
}
