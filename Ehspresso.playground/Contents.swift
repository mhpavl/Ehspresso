//: Playground - noun: a place where people can play

import UIKit
import Ehspresso

import PlaygroundSupport

enum WatchState: State {
    case inactive, active, waiting, doing, finished
}

enum WatchEvent: Event {
    case inactive, active, wait, start, showDoing, finish, reset
    
    var notificationName: Notification.Name {
        switch self {
        case .inactive:
            return .NSExtensionHostWillResignActive
        case .active:
            return .NSExtensionHostDidBecomeActive
        case .wait:
            return .WatchWait
        case .start:
            return .WatchDo
        case .showDoing:
            return .WatchShowDoing
        case .finish:
            return .WatchFinished
        case .reset:
            return .WatchReset
        }
    }
}

extension Notification.Name {
    static let WatchWait = Notification.Name("WatchWaitNotification")
    static let WatchDo = Notification.Name("WatchDoNotification")
    static let WatchShowDoing = Notification.Name("WatchShowDoingNotification")
    static let WatchFinished = Notification.Name("WatchFinishedNotification")
    static let WatchReset = Notification.Name("WatchResetNotification")
}


let transitions: [StateTransition<WatchState, WatchEvent>] = [
    StateTransition(fromState: .inactive, event: .active, toState: .active) {
        print("Watch Active")
    },
    StateTransition(fromState: .active, event: .wait, toState: .waiting) {
        print("Watch Wait")
    },
    StateTransition(fromState: .waiting, event: .start, toState: .doing) {
        print("Watch Do")
        Ehspresso.postEvent(WatchEvent.showDoing)
    },
    
    StateTransition(fromState: .doing, event: .showDoing, toState: .doing) {
        print("Doing")
    },
    
    /** 
     Comment out for Reachability property failure 
     */
    StateTransition(fromState: .doing, event: .finish, toState: .finished) {
        print("Watch Finished")
    },
    
    /** 
     Comment out for Liveness property failure, add WatchState.finished to acceptingStates to accept sink state
     */
    StateTransition(fromState: .finished, event: .reset, toState: .waiting) {
        print("Watch Wait 2")
    },
 

    
    /** 
     Uncomment for Deterministic property failure
    StateTransition(fromState: .finished, event: .reset, toState: .waiting) {
        print("Watch Finished 2")
    },
     */
]

PlaygroundPage.current.needsIndefiniteExecution = true

let fsm = try Ehspresso.Machine(initialState: .inactive, transitions: transitions, acceptingStates:[.waiting])


Ehspresso.postEvent(WatchEvent.active)
Ehspresso.postEvent(WatchEvent.wait)
Ehspresso.postEvent(WatchEvent.start)
Ehspresso.postEvent(WatchEvent.finish)


