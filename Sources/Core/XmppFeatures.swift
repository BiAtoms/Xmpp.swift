//
//  XmppFeatures.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/28/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

import Foundation

open class XmppFeatures: XmlElement {
    
    open func supportsMechanism(_ mechanism: String) -> Bool {
        return element(named: "mechanisms", xmlns: "urn:ietf:params:xml:ns:xmpp-sasl")?
            .element(named: "mechanism", text: mechanism) != nil
    }
    
    open func supportsAuthenticator(_ authenticator: XmppAuthenticator) -> Bool {
        return supportsMechanism(authenticator.mechanism)
    }
    
    open var supportsTls: Bool {
        return  element(named: "starttls", xmlns: "urn:ietf:params:xml:ns:xmpp-tls") != nil
    }
    
    open var requiresTls: Bool {
        return element(named: "starttls", xmlns: "urn:ietf:params:xml:ns:xmpp-tls")?
            .element(named: "required") != nil
    }
}
