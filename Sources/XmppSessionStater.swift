//
//  XmppSessionStater.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/28/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

import Foundation

public protocol XmppSessionStater {
    func start(jid: XmppJID) -> XmlElement
    func handleResponse(_ element: XmlElement) -> XmppSessionStarterResult
}

public enum XmppSessionStarterResult {
    case success
    case error(Error?)
    case `continue`(element: XmlElement)
}

