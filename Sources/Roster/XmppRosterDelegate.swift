//
//  XmppRosterDelegate.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 02/06/2018.
//  Copyright © 2018 BiAtoms. All rights reserved.
//

public protocol XmppRosterDelegate {
    func xmppRosterDidFetchContacts(_ roster: XmppRoster)
    func xmppRoster(_ roster: XmppRoster, didAdd contact: XmppContact)
    func xmppRoster(_ roster: XmppRoster, didUpdate contact: XmppContact)
    func xmppRoster(_ roster: XmppRoster, didRemove contact: XmppContact)
    
    func xmppRoster(_ roster: XmppRoster, didReceivePresenceSubsriptionRequestFrom jid: XmppJID)
    
    func xmppRoster(_ roster: XmppRoster, didAdd resource: XmppResource, to contact: XmppContact)
    func xmppRoster(_ roster: XmppRoster, didUpdate resource: XmppResource, for contact: XmppContact)
    func xmppRoster(_ roster: XmppRoster, didRemove resource: XmppResource, from contact: XmppContact)
}
