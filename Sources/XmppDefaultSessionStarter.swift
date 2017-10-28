//
//  XmppDefaultSessionStarter.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/28/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

open class XmppDefaultSessionStarter: XmppSessionStater {
    public func start(jid: XmppJID) -> XmlElement {
        let iq = XmppIQ(type: .set, id: .uuid)
        let session = XmlElement(name: "session", xmlns: "urn:ietf:params:xml:ns:xmpp-session")
        iq.children.append(session)
        return iq
    }
    
    public func handleResponse(_ element: XmlElement) -> XmppSessionStarterResult {
        return element.attributes["type"] == "result" ? .success : .error(nil)
    }
}
