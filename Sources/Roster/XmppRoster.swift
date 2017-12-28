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
    
    private func query(block: ((XmlElement)->Void)) {
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
                print("received all contacts")
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
                print("removed contact")
                delegate.invoke {
                    $0.xmppRoster(self, didRemove: contact)
                }
            } else {
                // update
                let contact = XmppContact(item: item)
                contacts[idx] = contact
                print("updated contact")
                delegate.invoke {
                    $0.xmppRoster(self, didUpdate: contact)
                }
            }
        } else {
            // new contact
            let contact = XmppContact(item: item)
            contacts.append(contact)
            print("added new contact")
            delegate.invoke {
                $0.xmppRoster(self, didAdd: contact)
            }
        }
    }
    
    public func stream(_ stream: XmppStream, didReceive presence: XmppPresence) {

    }
    
    public func streamDidAuthenticate(_ stream: XmppStream) {
        fetchContacts()
    }
}

public protocol XmppRosterDelegate {
    func xmppRosterDidFetchContacts(_ roster: XmppRoster)
    func xmppRoster(_ roster: XmppRoster, didAdd contact: XmppContact)
    func xmppRoster(_ roster: XmppRoster, didUpdate contact: XmppContact)
    func xmppRoster(_ roster: XmppRoster, didRemove contact: XmppContact)
}
