//
//  XmppContact.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 12/28/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

open class XmppContact {
    var jid: XmppJID
    var name: String
    var subscription: Subscription
    var groups: [String]
    var isPendingApproval: Bool
    
    init(item: XmlElement) {
        assert(item.name == "item")
        jid = XmppJID(parsing: item["jid"])!
        name = item["name"] ?? ""
        subscription = Subscription(rawValue: item["subscription"] ?? "none")!
        groups = item.children.map {
            assert($0.name == "group")
            return $0.text
        }
        isPendingApproval = item["ask"] != nil
        assert(!isPendingApproval || item["ask"] == "subscribe")
    }
    
    enum Subscription: String {
        case none
        case to
        case from
        case both
    }
}
