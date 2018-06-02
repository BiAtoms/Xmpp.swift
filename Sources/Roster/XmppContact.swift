//
//  XmppContact.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 12/28/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

open class XmppContact {
    open var jid: XmppJID
    open var name: String
    open var groups: [String]
    open var resources: [XmppResource] = []
    
    open var item: XmlElement?
    open var isPendingApproval: Bool {
        assert(!(item?["ask"] != nil) || item?["ask"] == "subscribe")
        return item?["ask"] != nil
    }
    open var subscription: Subscription {
        return Subscription(rawValue: item?["subscription"] ?? "none")!
    }
    
    init(item: XmlElement) {
        assert(item.name == "item")
        self.item = item
        jid = XmppJID(parsing: item["jid"])!
        name = item["name"] ?? ""
        groups = item.children.map {
            assert($0.name == "group")
            return $0.text
        }
    }
    
    public enum Subscription: String {
        case none
        case to
        case from
        case both
    }
    
    /// Update resources array with presence
    ///
    /// - Parameter presence: XmppPresence to update. only .available and .unavailable is valid
    /// - Returns: nil on no change, otherwise tuple of ChangeType and XmppResource
    open func update(with presence: XmppPresence) -> (type: ChangeType, resource: XmppResource)? {
        guard presence.type == .available || presence.type == .unavailable
            else { return nil }
        
        if let idx = resources.index(where: { $0.jid.full == presence.from!.full }) {
            let resource = resources[idx]
            if presence.type == .unavailable {
                resources.remove(at: idx)
                return (.removed, resource)
            }
            
            resources[idx] = XmppResource(presence: presence)
            return (.updated, resource)
        }
        
        guard presence.type == .available else { return nil }
        let resource = XmppResource(presence: presence)
        resources.append(resource)
        return (.added, resource)
    }
    
    public enum ChangeType {
        case added
        case updated
        case removed
    }
}
