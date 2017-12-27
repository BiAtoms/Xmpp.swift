//
//  XmppAnonymusAuthenticator.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/23/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

import Foundation

open class XmppAnonymusAuthenticator: XmppAuthenticator {
    open var mechanism: String { return "ANONYMOUS" }
    
    open func start(jid: XmppJID, password: String) -> XmlElement {
        return authElement
    }
    
    open func handleResponse(_ element: XmlElement) -> XmppAuthenticatorResult {
        return element.name == "success" ? .success : .error
    }
    
    public init() {}
}
