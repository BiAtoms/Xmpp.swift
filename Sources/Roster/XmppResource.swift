//
//  XmppResource.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 02/06/2018.
//  Copyright © 2018 BiAtoms. All rights reserved.
//

open class XmppResource {
    open var presence: XmppPresence
    open var jid: XmppJID {
        return presence.from!
    }
    
    public init(presence: XmppPresence) {
        self.presence = presence
    }
}
