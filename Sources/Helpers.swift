//
//  Helpers.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 10/26/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

import Dispatch
import XmlSwift
import SocketSwift

public typealias Socket = SocketSwift.Socket
public typealias XmlElement = XmlSwift.XmlElement
public typealias DispatchQueue = Dispatch.DispatchQueue
public typealias Port = SocketSwift.Port
public typealias Byte = SocketSwift.Byte

extension String {
    internal var bytes: [Byte] {
        return ([Byte])(self.utf8)
    }
    
    internal var base64Encoded: String {
        return Data(self.utf8).base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
    }
}
