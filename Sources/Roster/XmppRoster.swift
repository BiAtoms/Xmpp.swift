//
//  XmppRoster.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 12/27/17.
//

open class XmppRoster {
    open let stream: XmppStream
    open var delegate = MulticastDelegate<XmppRosterDelegate>()
    public init(stream: XmppStream) {
        self.stream = stream
        stream.delegate.add(self)
    }
    
    open let idHolder = IdHolder()
    open var contacts: [XmppContact] = []
    
    open func fetchContacts() {
        assert(stream.state == .connected)
        let iq = XmppIQ(type: .get, id: idHolder.newId)
        iq.children.append(XmlElement(name: "query", xmlns: "jabber:iq:roster"))
        stream.send(element: iq)
        awaitingContacts = true
    }
    
    open func remove(contact: XmppContact) {
        assert(contacts.contains(where: { $0.jid.bare == contact.jid.bare }))
        query {
            $0["jid"] = contact.jid.bare
            $0["subscription"] = "remove"
        }
    }
    
    open func addOrUpdate(contact: XmppContact) {
        query { item in
            item["jid"] = contact.jid.bare
            item["name"] = contact.name.isEmpty ? nil : contact.name
            contact.groups.forEach {
                item.children.append(XmlElement(name: "group", text: $0))
            }
        }
    }
    
    open func unsubscribe(from jid: XmppJID) {
        denySubscriptionRequest(of: jid)
    }
    
    open func subscribe(to jid: XmppJID) {
        presence(to: jid, type: .subscribe)
    }
    
    open func approveSubscriptionRequest(of jid: XmppJID) {
        presence(to: jid, type: .subscribed)
        
        // TODO: auto-subscribe option
    }
    
    open func denySubscriptionRequest(of jid: XmppJID) {
        presence(to: jid, type: .unsubscribed)
    }
    

    private func presence(to jid: XmppJID, type: XmppPresenceType) {
        // TODO: jid.bare should be sent
        stream.send(element: XmppPresence(type: type, to: jid))
    }
    
    private func query(block: ((XmlElement) ->Void)) {
        let iq = XmppIQ(type: .set, id: idHolder.newId)
        let query = XmlElement(name: "query", xmlns: "jabber:iq:roster")
        let item = XmlElement(name: "item")
        block(item)
        query.children.append(item)
        iq.children.append(query)
        stream.send(element: iq)
    }
    
    private var awaitingContacts = false
}

extension XmppRoster: XmppStreamDelegate {
    public func stream(_ stream: XmppStream, didReceive iq: XmppIQ) -> Bool {
        guard let query = iq.element(named: "query", xmlns: "jabber:iq:roster")
            else { return false }
        
        if idHolder.has(iq.id) { // response to our query
            assert(iq.type! == .result)
            if awaitingContacts {
                awaitingContacts = false
                contacts = query.children.map { XmppContact(item: $0) }
                delegate.invoke {
                    $0.xmppRosterDidFetchContacts(self)
                }
            } else {
                handleQuery(query)
            }
        } else { // roster push
            assert(iq.type! == .set)
            handleQuery(query)
            stream.send(element: XmppIQ(type: .result, from: stream.jid, id: iq.id))
        }
        
        return true
    }
    
    /// The same logic for roster push and roster update by us
    private func handleQuery(_ query: XmlElement) {
        assert(query.children.count == 1)
        assert(query.children[0].name == "item")
        let item = query.children[0]
        if let idx = contacts.index(where: { $0.jid.bare == item["jid"] }) {
            if item["subscription"] == "remove" {
                // remove from contact list
                let contact = contacts.remove(at: idx)
                delegate.invoke {
                    $0.xmppRoster(self, didRemove: contact)
                }
            } else {
                // update
                // TODO: consider jid.resource ???
                let contact = XmppContact(item: item)
                contacts[idx] = contact
                delegate.invoke {
                    $0.xmppRoster(self, didUpdate: contact)
                }
            }
        } else {
            // new contact
            let contact = XmppContact(item: item)
            contacts.append(contact)
            delegate.invoke {
                $0.xmppRoster(self, didAdd: contact)
            }
        }
    }
    
    public func stream(_ stream: XmppStream, didReceive presence: XmppPresence) {
        if presence.type == .subscribe {
            //TODO: auto-accept for known users
            delegate.invoke {
                $0.xmppRoster(self, didReceivePresenceSubsriptionRequestFrom: presence.from!)
            }
            return
        }

        if presence.type == .available || presence.type == .unavailable {
            if let contact = contacts.first(where: { $0.jid.bare == presence.from!.bare }) {
                if let (type, resource) = contact.update(with: presence) {
                    switch type {
                    case .added:
                        delegate.invoke {
                            $0.xmppRoster(self, didAdd: resource, to: contact)
                        }
                    case .updated:
                        delegate.invoke {
                            $0.xmppRoster(self, didUpdate: resource, for: contact)
                        }
                    case .removed:
                        delegate.invoke {
                            $0.xmppRoster(self, didRemove: resource, from: contact)
                        }
                    }
                }
            } else {
                if stream.jid.bare == presence.from!.bare {
                    // TODO: update my presence resources
                    // it's me
                } else {
                    // someone unknown? use stream.jid
                }
            }
        } else {
            // we ignore other types since server will send roster pushes
        }
    }
    
    public func streamDidAuthenticate(_ stream: XmppStream) {
        // TODO: add option to opt out of autofetch
        fetchContacts()
    }
}
