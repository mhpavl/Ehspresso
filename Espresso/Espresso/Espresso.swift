//
//  Espresso.swift
//  Espresso
//
//  Created by Mark H Pavlidis on 4/23/2015.
//  Copyright (c) 2015 Grok Software Ltd. All rights reserved.
//

import Foundation

public protocol StateProtocol: Equatable, Hashable , CustomStringConvertible {
    static var allStates: [Self] { get }
}

public protocol EventProtocol: Equatable, Hashable , CustomStringConvertible {
    static var allEvents: [Self] { get }
    var notificationName: String { get }
}

public struct StateTransition<S: StateProtocol, E: EventProtocol>: Equatable {
    public typealias Action = () -> Void
    
    let fromState: S        // Source State
    let event: E            // Event
    let toState: S          // Target State
    let action: Action?     // Runs on an arbitrary queue, bounce UI to the main thread
    
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

enum MachineValidationError: ErrorType {
    case Reachability, Liveness, Determinisic
}

final public class Machine<S: StateProtocol, E: EventProtocol> {
    let states: [S]
    private(set) var state: S {
        didSet {
            debugPrint("Espresso state changed: \(oldValue.description) -> \(state.description)")
        }
    }
    let acceptingStates: [S]
    let events: [E]
    let transitions: [StateTransition<S, E>]
    
    var eventObservers: [AnyObject]
    
    private let queue: dispatch_queue_t = dispatch_queue_create("com.flixel.fsm.queue", DISPATCH_QUEUE_SERIAL);
    
    public init(initialState: S, transitions: [StateTransition<S, E>], acceptingStates: [S]) throws {
        self.states = S.allStates
        self.state = initialState
        self.acceptingStates = acceptingStates
        self.events = E.allEvents
        self.transitions = transitions
        self.eventObservers = [AnyObject]()
        
        for event in events {
            eventObservers.append(NSNotificationCenter.defaultCenter().addObserverForName(event.notificationName, object: nil, queue: nil, usingBlock: { [weak self] notification in
                    self?.handleEvent(event)
                }))
        }
        
        try validateStatesReachable(initialState)   // "Espresso Machine failed reachability property"
        try validateLiveness(self.acceptingStates)  // "Espresso Machine failed liveness property")
        try validateDeterministic()                 // "Espresso Machine failed deterministic property")
    }
    
    deinit {
        for _ in events {
            for observer in eventObservers {
                NSNotificationCenter.defaultCenter().removeObserver(observer)
            }
        }
    }
    
    func handleEvent(event:E) {
        dispatch_sync(self.queue, { () -> Void in
            if let transition = self.transitions.filter({ $0.fromState == self.state && $0.event == event }).first {
                self.state = transition.toState
                transition.action?()
            }
        })
    }
    
    func validateStatesReachable(initialState: S) throws {
        let reachableStates = transitions.reduce(Set(arrayLiteral: initialState)) { $0.union(Set(arrayLiteral: $1.toState)) }
        let unreachableStates = Set(states).subtract(reachableStates)
        if !unreachableStates.isEmpty {
            debugPrint("Unreachable States: " + Array(arrayLiteral: unreachableStates).map({ $0.description }).joinWithSeparator(","))
            throw MachineValidationError.Reachability
        }
    }
    
    func validateLiveness(acceptingStates: [S]) throws {
        let liveStates = transitions.reduce(Set()) {
            $1.fromState != $1.toState ? $0.union(Set(arrayLiteral: $1.fromState)) : Set()
        }
        let sinkStates = Set(states).subtract(liveStates).subtract(acceptingStates)
        if !sinkStates.isEmpty {
            debugPrint("Sink States: " + Array(arrayLiteral: sinkStates).map({ $0.description }).joinWithSeparator(","))
            throw MachineValidationError.Liveness
        }
    }
    
    func validateDeterministic() throws {
        for transition in transitions {
            let t = transitions.filter({$0 == transition})
            if t.count > 1 {
                debugPrint("Non-unique transition: \(transition)")
                throw MachineValidationError.Determinisic
            }
        }
    }
}

public func postEvent<E: EventProtocol>(event: E) {
    NSNotificationCenter.defaultCenter().postNotificationName(event.notificationName, object: nil)
}
