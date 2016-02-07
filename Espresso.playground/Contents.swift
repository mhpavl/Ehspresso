//: Playground - noun: a place where people can play

import UIKit
import Espresso


enum WatchState: Int, StateProtocol {
    case Inactive, Active, Waiting, Doing, Finished
    static var allStates: [WatchState] {
        return [Inactive, Active, Waiting, Doing, Finished]
    }
    var description: String { return String(self.rawValue) }
}

enum WatchEvent: Int, EventProtocol {
    case Inactive, Active, Wait, Do, ShowDoing, ShowFinished, Reset
    
    static var allEvents: [WatchEvent] {
        return [Inactive, Active, Wait, Do, ShowDoing, ShowFinished, Reset]
    }
    
    var notificationName: String {
        switch self {
        case .Inactive:
            return NSExtensionHostWillResignActiveNotification
        case .Active:
            return NSExtensionHostDidBecomeActiveNotification
        case .Wait:
            return "WatchWaitNotification"
        case .Do:
            return "WatchDoNotification"
        case .ShowDoing:
            return "WatchShowDoingNotification"
        case .ShowFinished:
            return "WatchShowFinishedNotification"
        case .Reset:
            return "WatchResetNotification"
        }
    }
    
    var description: String { return String(self.rawValue) }
}

let transitions = [
    StateTransition(fromState: WatchState.Inactive, event: WatchEvent.Active, toState: WatchState.Active, action: {
        print("Watch Active")
    }),
    StateTransition(fromState: WatchState.Active, event: WatchEvent.Wait, toState: WatchState.Waiting, action: {
        print("Watch Wait")
    }),
    StateTransition(fromState: WatchState.Waiting, event: WatchEvent.Do, toState: WatchState.Doing, action: {
        print("Watch Do")
    }),
    
    /* Comment out for Reachability property failure */
    StateTransition(fromState: WatchState.Doing, event: WatchEvent.ShowFinished, toState: WatchState.Finished, action: {
        print("Watch Finished")
    }),
    
    /** Comment out for Liveness property failure
        Add WatchState.Finished to acceptingStates to accept sink state
    */
    StateTransition(fromState: WatchState.Finished, event: WatchEvent.Reset, toState: WatchState.Waiting, action: {
        print("Watch Wait 2")
    }),
    
    /** Uncomment for Deterministic property failure
    StateTransition(fromState: WatchState.Finished, event: WatchEvent.Reset, toState: WatchState.Waiting, action: {
        print("Watch Finished 2")
    }),
    */
]

let fsm = try Espresso.Machine(initialState: WatchState.Inactive, transitions: transitions, acceptingStates:[])

Espresso.postEvent(WatchEvent.Active)
Espresso.postEvent(WatchEvent.Wait)
Espresso.postEvent(WatchEvent.Do)
Espresso.postEvent(WatchEvent.ShowFinished)

