//
//  XmppBinder.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/28/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

import Foundation

public protocol XmppBinder {
    func start(jid: XmppJID) -> XmlElement     
    func handleResponse(_ element: XmlElement) -> XmppBinderResult
}

public enum XmppBinderResult {
    case success
    case error(Error?)
    case `continue`(element: XmlElement)
}
