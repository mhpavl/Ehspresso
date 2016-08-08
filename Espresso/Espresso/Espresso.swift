//
//  Espresso.swift
//  Espresso
//
//  Created by Mark H Pavlidis on 4/23/2015.
//  Copyright (c) 2015 Grok Software Ltd. All rights reserved.
//

import Foundation

public protocol StateProtocol: Equatable, Hashable, CustomStringConvertible {
    static var allStates: Set<Self> { get }
}

public protocol EventProtocol: Equatable, Hashable, CustomStringConvertible {
    static var allEvents: Set<Self> { get }
    var notificationName: Notification.Name { get }
}

public struct StateTransition<S: StateProtocol, E: EventProtocol>: Equatable {
    public typealias Action = () -> Void
    
    let fromState: S        // Source State
    let event: E            // Event
    let toState: S          // Target State
    let action: Action?     // Runs on an arbitrary queue
    
    public init(fromState: S, event: E, toState: S, action: Action?) {
        self.fromState = fromState
        self.event = event
        self.toState = toState
        self.action = action
    }
}

public func ==<S, T>(lhs: StateTransition<S, T>, rhs: StateTransition<S, T>) -> Bool {
    return (lhs.fromState == rhs.fromState && lhs.event == rhs.event && lhs.toState == rhs.toState)
}

enum MachineValidationError: Error {
    case reachability, liveness, determinisic
}

final public class Machine<S: StateProtocol, E: EventProtocol> {
    let states: Set<S>
    private(set) var state: S {
        didSet {
            debugPrint("Espresso state changed: \(oldValue.description) -> \(state.description)")
        }
    }
    let acceptingStates: Set<S>
    let events: Set<E>
    let transitions: [StateTransition<S, E>]
    
    var eventObservers: [AnyObject]
    
    private let queue: DispatchQueue = DispatchQueue(label: "espresso.queue")
    
    public init(initialState: S, transitions: [StateTransition<S, E>], acceptingStates: Set<S>) throws {
        self.states = S.allStates
        self.state = initialState
        self.acceptingStates = acceptingStates
        self.events = E.allEvents
        self.transitions = transitions
        self.eventObservers = [AnyObject]()
        
        for event in events {
            eventObservers.append(NotificationCenter.default.addObserver(forName: event.notificationName, object: nil, queue: nil) { [weak self] _ in
                    self?.handleEvent(event)
                })
        }
        
        try validateStatesReachable(initialState)   // "Espresso Machine failed reachability property"
        try validateLiveness(self.acceptingStates)  // "Espresso Machine failed liveness property")
        try validateDeterministic()                 // "Espresso Machine failed deterministic property")
    }
    
    deinit {
        for observer in eventObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func handleEvent(_ event:E) {
        queue.async {
            if let transition = self.transitions.filter({ $0.fromState == self.state && $0.event == event }).first {
                self.state = transition.toState
                transition.action?()
            }
        }
    }
    
    func validateStatesReachable(_ initialState: S) throws {
        let reachableStates = transitions.reduce(Set(arrayLiteral: initialState)) { $0.union(Set(arrayLiteral: $1.toState)) }
        let unreachableStates = Set(states).subtracting(reachableStates)
        if !unreachableStates.isEmpty {
            debugPrint("Unreachable States: " + Array(arrayLiteral: unreachableStates).map({ $0.description }).joined(separator: ","))
            throw MachineValidationError.reachability
        }
    }
    
    func validateLiveness(_ acceptingStates: Set<S>) throws {
        let liveStates = transitions.reduce(Set()) {
            $1.fromState != $1.toState ? $0.union(Set(arrayLiteral: $1.fromState)) : Set()
        }
        let sinkStates = Set(states).subtracting(liveStates).subtracting(acceptingStates)
        if !sinkStates.isEmpty {
            debugPrint("Sink States: " + Array(arrayLiteral: sinkStates).map({ $0.description }).joined(separator: ","))
            throw MachineValidationError.liveness
        }
    }
    
    func validateDeterministic() throws {
        for transition in transitions {
            let t = transitions.filter({$0 == transition})
            if t.count > 1 {
                debugPrint("Non-unique transition: \(transition)")
                throw MachineValidationError.determinisic
            }
        }
    }
}

public func postEvent<E: EventProtocol>(_ event: E) {
    NotificationCenter.default.post(name: event.notificationName, object: nil)
}
