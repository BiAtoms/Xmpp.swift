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
    open func element(named name: String, xmlns: String? = nil, text: String? = nil) -> XmlElement? {
        return self.children.first {
            $0.name == name &&
            (xmlns == nil || $0.attributes["xmlns"] == xmlns) &&
            (text == nil || $0.text == text)
        }
    }
    
    public convenience init(_ other: XmlElement) {
        self.init(name: other.name)
        self.attributes = other.attributes
        self.children = other.children
        self.parent = other.parent
        self.text = other.text
    }
}

extension MulticastDelegate {
    public func invokeAndStopIf<R: Equatable>(_ value: R,_ invocation: (T) -> R) -> Bool {
        for delegate in delegates {
            guard let v = delegate.value as? T else { continue }
            if invocation(v) == value {
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


open class IdHolder {
    open var ids: Set<String> = []
    open func contains(_ id: String?) -> Bool {
        guard let id = id else { return false }
        return ids.contains(id)
    }
    
    open func has(_ id: String?) -> Bool {
        if contains(id) {
            remove(id!)
            return true
        }
        
        return false
    }
    
    open func add(_ id: String) {
        let (inserted, _) = ids.insert(id)
        assert(inserted)
    }
    open func remove(_ id: String) {
        ids.remove(id)
    }
    
    open var newId: String {
        let id = UUID().uuidString
        add(id)
        return id
    }
}

