//
//  FirstViewController.swift
//  EspressoDemo
//
//  Created by Mark H Pavlidis on 4/26/2015.
//  Copyright (c) 2015 Grok Software Ltd. All rights reserved.
//

import UIKit
import Espresso

class FirstViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let _ = try! Espresso.Machine(initialState: .inactive, transitions: transitions, acceptingStates:[])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            Espresso.postEvent(WatchEvent.active)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            Espresso.postEvent(WatchEvent.wait)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4)) {
            Espresso.postEvent(WatchEvent.start)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(8)) {
            Espresso.postEvent(WatchEvent.finish)
        }
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
            Espresso.postEvent(WatchEvent.showDoing)
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
         */
         StateTransition(fromState: .finished, event: .reset, toState: .waiting) {
         print("Watch Finished 2")
         },
 
    ]
}



enum WatchState: State {
    case inactive, active, waiting, doing, finished
    static var allStates: Set<WatchState> {
        return [inactive, active, waiting, doing, finished]
    }
}

enum WatchEvent: Event {
    case inactive, active, wait, start, showDoing, finish, reset
    
    static var allEvents: Set<WatchEvent> {
        return [inactive, active, wait, start, showDoing, finish, reset]
    }
    
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

