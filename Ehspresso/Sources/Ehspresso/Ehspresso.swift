//
//  Ehspresso.swift
//  Ehspresso
//
//  Created by Mark H Pavlidis on 4/23/2015.
//  Copyright (c) 2015 Grok Software Ltd. All rights reserved.
//

import Foundation

public protocol State: Hashable, CaseIterable {
    static var allStates: Set<Self> { get }
}

public extension State {
    static var allStates: Set<Self> {
        return Set(allCases)
    }
}

public protocol Event: Hashable, CaseIterable {
    static var allEvents: Set<Self> { get }
    var notificationName: Notification.Name { get }
}

public extension Event {
    static var allEvents: Set<Self> {
        return Set(allCases)
    }
}

public struct StateTransition<S: State, E: Event>: Equatable {
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

    static public func ==(lhs: StateTransition<S, E>, rhs: StateTransition<S, E>) -> Bool {
        return (lhs.fromState == rhs.fromState && lhs.event == rhs.event && lhs.toState == rhs.toState)
    }
}


public enum MachineValidationError: Error {
    case reachability
    case liveness
    case deterministic
}

final public class Machine<S: State, E: Event> {
    let states: Set<S>
    public private(set) var state: S {
        didSet {
            debugPrint("Espresso state changed: \(oldValue) -> \(state)")
        }
    }
    let acceptingStates: Set<S>
    let events: Set<E>
    let transitions: [StateTransition<S, E>]

    var eventObservers: [NSObjectProtocol]

    private let queue: DispatchQueue = DispatchQueue(label: "espresso.queue")

    public init(initialState: S, transitions: [StateTransition<S, E>], acceptingStates: Set<S>) throws {
        states = S.allStates
        state = initialState
        self.acceptingStates = acceptingStates
        events = E.allEvents
        self.transitions = transitions
        eventObservers = []

        for event in events {
            eventObservers.append(NotificationCenter.default.addObserver(forName: event.notificationName, object: nil, queue: nil) { [weak self] _ in
                self?.handleEvent(event)
                })
        }

        try validateStatesReachable(initialState)   // "Espresso Machine failed reachability property"
        try validateLiveness(acceptingStates)  // "Espresso Machine failed liveness property")
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
        let unreachableStates = states.subtracting(reachableStates)
        if !unreachableStates.isEmpty {
            debugPrint("Unreachable States: " + Array(arrayLiteral: unreachableStates).map({ $0.description }).joined(separator: ","))
            throw MachineValidationError.reachability
        }
    }

    func validateLiveness(_ acceptingStates: Set<S>) throws {
        let liveStates = transitions.reduce(Set()) {
            $1.fromState != $1.toState ? $0.union([$1.fromState]) : $0
        }
        let sinkStates = states.subtracting(liveStates).subtracting(acceptingStates)
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
                throw MachineValidationError.deterministic
            }
        }
    }
}

public func postEvent<E: Event>(_ event: E) {
    NotificationCenter.default.post(name: event.notificationName, object: nil)
}

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "EhspressoMacros", type: "StringifyMacro")
