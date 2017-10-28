//
//  XmppFeatures.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/28/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

import Foundation

open class XmppFeatures: XmlElement {
    
    open var needsBinding: Bool {
        return self.element(named: "bind", xmlns: "urn:ietf:params:xml:ns:xmpp-bind") != nil
    }
    
    open var needsSession: Bool {
        return self.element(named: "session", xmlns: "urn:ietf:params:xml:ns:xmpp-session") != nil
    }
}
