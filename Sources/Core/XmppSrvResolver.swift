//
//  XmppSrvResolver.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 11/9/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

import Foundation
import SocketSwift
import dnssd

open class XmppSrvResolver {
    public struct Record {
       public var priority: Int
       public var weight: Int
       public var port: Port
       public var target: String
    }
    private var records: [Record] = []
}


extension XmppSrvResolver {
    open static func resolve(domain: String, timeout: TimeInterval) -> [Record]? {
        return resolve(srv: "_xmpp-client._tcp.\(domain)", timeout: timeout)
    }
    
    open static func resolve(srv: String, timeout: TimeInterval) -> [Record]? {
        let `self` = XmppSrvResolver() //instance will hold `records`
    
        var dump = 0
        let ref: UnsafeMutablePointer<DNSServiceRef?> = { (ptr: UnsafeRawPointer) in
            return UnsafeMutablePointer(OpaquePointer(ptr))
        }(&dump) // creating `UnsafeMutablePointer<DNSServiceRef?>`. Couln't find any other simple way
    
        guard DNSServiceQueryRecord(ref,
                                    DNSServiceFlags(0),
                                    UInt32(0),
                                    srv,
                                    UInt16(kDNSServiceType_SRV),
                                    UInt16(kDNSServiceClass_IN),
                                    queryRecordCallback,
                                    bridge(obj: self)) == kDNSServiceErr_NoError else { return nil }
        defer { DNSServiceRefDeallocate(ref.pointee) }
        
        let socket = Socket(with: DNSServiceRefSockFD(ref.pointee))
        guard let available = try? socket.wait(for: .read, timeout: timeout),
            available else {
            return nil
        }
        
        // DNSServiceProcessResult will block until result processing is finished.
        // that means `self.records` will be available when the function returns
        // see https://opensource.apple.com/source/mDNSResponder/mDNSResponder-878.1.1/mDNSShared/dnssd_clientstub.c
        guard DNSServiceProcessResult(ref.pointee) == kDNSServiceErr_NoError else {
            return nil
        }
        
        return self.records
    }
    
    private class var queryRecordCallback: DNSServiceQueryRecordReply {
        return { sdRef, flags, errorCode, interfaceIndex, fullname, rrtype, rrclass, rdlen, rddata, ttl, context in
            let `self`: XmppSrvResolver = bridge(ptr: context!)
            func readUInt16(_ ptr: UnsafeRawPointer, offset: Int) -> UInt16 {
                return ptr.advanced(by: offset).bindMemory(to: UInt16.self, capacity: MemoryLayout<UInt16>.size).pointee.bigEndian
            }
            let ptr = rddata!
            let priority = readUInt16(ptr, offset: 0)
            let weight = readUInt16(ptr, offset: 2)
            let port = readUInt16(ptr, offset: 4)
            
            let arr = UnsafeBufferPointer<UInt8>(start: ptr.advanced(by: 6).bindMemory(to: UInt8.self, capacity: MemoryLayout<UInt8>.size), count: Int(rdlen) - 6)
            let target = XmppSrvResolver.parseDomainName(arr)
            
            self.records.append(Record(priority: Int(priority), weight: Int(weight), port: Port(port), target: target))
            
            if flags & DNSServiceFlags(kDNSServiceFlagsMoreComing) == 0 {
                // done
            }
        }
    }
    
    private class func parseDomainName(_ ptr: UnsafeBufferPointer<UInt8>) -> String {
        var name = ""
        var i = 0
        //TODO: what if we have compressed data? see https://tools.ietf.org/html/rfc1035#section-4.1.4
        while true {
            let numberOfBytesToRead = Int(ptr[i])
            i += 1
            let lastByteIndex = i + numberOfBytesToRead
            
            while i < lastByteIndex {
                name.append(Character(UnicodeScalar(ptr[i])))
                i += 1
            }
            
            if i == ptr.count - 1 { // end of pointer
                break
            } else {
                name += "."
            }
        }
        return name
    }
}
