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
}

extension XmppJID {
    public convenience init?(parsing string: String?) {
        guard let string = string
            else { return nil }
        
        let l = string.components(separatedBy: "@")
        let s = l.last?.components(separatedBy: "/")
        guard let user = l.first,
            let domain = s?.first else {
                return nil
        }
        let resource = s?.last
        
        //TODO: what is "string prep"?
        self.init(user: user, domain: domain, resource: resource)
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
