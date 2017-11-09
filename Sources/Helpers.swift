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
    
    internal static var uuid: String {
        return UUID().uuidString
    }
}

extension XmlElement {
    func element(named name: String, xmlns: String? = nil, text: String? = nil) -> XmlElement? {
        return self.children.first {
            $0.name == name &&
            (xmlns == nil || $0.attributes["xmlns"] == xmlns) &&
            (text == nil || $0.text == text)
        }
    }
    
    convenience init(_ other: XmlElement) {
        self.init(name: other.name)
        self.attributes = other.attributes
        self.children = other.children
        self.parent = other.parent
        self.text = other.text
    }
}

extension MulticastDelegate {
    public func invokeAndStopIf<R: Equatable>(_ value: R,_ invocation: (T) -> R) -> Bool {
        for delegate in delegates.allObjects {
            if invocation(delegate as! T) == value {
                return true //stopped
            }
        }
        
        return false //not stopped
    }
}


func bridge<T : AnyObject>(obj : T) -> UnsafeMutableRawPointer {
    return UnsafeMutableRawPointer(Unmanaged.passUnretained(obj).toOpaque())
}

func bridge<T : AnyObject>(ptr : UnsafeRawPointer) -> T {
    return Unmanaged<T>.fromOpaque(ptr).takeUnretainedValue()
}

