//
//  MulticastDelegate.swift
//  XmppSwift
//
//  Created by Orkhan Alikhanov on 12/18/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

import Foundation

// Using `MulticastDelegate<T: MyProtocol>` and calling `MulticastDelegate<MyProtocol>()`
// does not compile. Therefore we avoid it
// See https://bugs.swift.org/browse/SR-55

open class MulticastDelegate<T> {
    internal var delegates = [WeakWrapper]()
    
    public init() { }
    
    open func add(_ delegate: T, queue: DispatchQueue = .main) {
        guard !contains(delegate) else { return }
        delegates.append(WeakWrapper(value: delegate as AnyObject, queue: queue))
    }
    
    open func remove(_ delegate: T) {
        once(delegate) { delegates.remove(at: $0) }
    }
    
    open func contains(_ delegate: T) -> Bool {
        var result = false
        once(delegate) { _ in result = true }
        return result
    }
    
    open func invoke(_ block: @escaping (T) -> ()) {
        walking { delegate, queue, _ in
            queue.async {
                block(delegate as! T)
            }
        }
    }
    
    internal class WeakWrapper {
        weak var value: AnyObject?
        var queue: DispatchQueue
        
        init(value: AnyObject, queue: DispatchQueue) {
            self.value = value
            self.queue = queue
        }
    }
}


extension MulticastDelegate {
    private func once(_ delegate: T, _ block: (Int) -> Void) {
        walking { value, _, idx in
            if value === delegate as AnyObject {
                block(idx)
                idx = delegates.count // break loop
            }
        }
    }
    
    internal func walking(_ block: (AnyObject, DispatchQueue, inout Int) -> Void) {
        var i = 0
        while i < delegates.count {
            if let d = delegates[i].value {
                block(d, delegates[i].queue, &i)
                i += 1
            } else {
                delegates.remove(at: i)
            }
        }
    }
}
