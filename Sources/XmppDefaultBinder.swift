//
//  XmppDefaultBinder.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/28/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

import Foundation

open class XmppDefaultBinder: XmppBinder {
    public func start(jid: XmppJID) -> XmlElement {
        let iq = XmppIQ(type: .set, id: .uuid)
        let bind = XmlElement(name: "bind", xmlns: "urn:ietf:params:xml:ns:xmpp-bind")
        if let resourceString = jid.resource {
            let resource = XmlElement(name: "resource")
            resource.text = resourceString
            bind.children.append(resource)
        }
        iq.children.append(bind)
        return iq
    }
    
    public func handleResponse(_ element: XmlElement) -> XmppBinderResult {
        return .success
    }
    
    //
}
