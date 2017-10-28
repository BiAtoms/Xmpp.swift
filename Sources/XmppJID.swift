//
//  XmppJID.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/21/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

import Foundation

//https://xmpp.org/extensions/xep-0029.html
open class XmppJID {
    open let user: String
    open let domain: String
    open let resource: String?
    
    public init(user: String, domain: String, resource: String? = nil) {
        self.user = user
        self.domain = domain
        self.resource = resource
    }
    
    open var bare: String {
        return "\(user)@\(domain)"
    }
    
    
    open var full: String {
        guard let resource = resource else {
            return bare
        }
        return bare + "/\(resource)"
    }
}
