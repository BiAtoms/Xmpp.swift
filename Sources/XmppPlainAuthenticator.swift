//
//  XmppPlainAuthenticator.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/23/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

import Foundation

open class XmppPlainAuthenticator: XmppSASLAuthenticator {
    override open var mechanism: String { return "PLAIN" }
}
