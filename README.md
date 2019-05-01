# Espresso

Espresso is a Mealy-style finite state machine written in Swift. 

## Motivation
Typically, state is implicit and inferred by checking a combination of view, controller, or other properties. Actions - UI change or inter-process communication - that cause a state transition can have complex predicates guarding the many possible transitions. Often this is the cause of bugs because some case is not covered or is not unique. 

By modeling the state, events, and state transitions, we can express our system using state diagrams or tables. There was once a great divide between formal software design methods and implementation (i.e., Parnas Tables to assembly, FORTRAN, C). Advances in toolchians helps to bridge that divide. 

The goal of this project is to explore how to use LLVM and Swift to pragmatically introduce formal methods to Swift projects.

## Finite State Machines  
*complete prose description and formal definition here*

## Currrent Release
- Stable: none
- Development: none

## Features 
*list Espresso features*

## Requirements  
- iOS 9.3+/Mac OS X 10.10+
- Xcode 10.1
- Swift 4.2

## Usage 

### Define States

### Define Events

### Define State Transitions 

### Define State Machine

### Fire Events 


## Credits
Espresso is developed and maintained by ([@mhp](https://twitter.com/mhp)). 

## License 
Espresso is released under the MIT license. See LICENSE for details.
