--[[
	State v0.1.1
	Author: Great_Bird
	Date: 2024-04-07
	Last updated: 2025-02-12
	
	Event-based table-driven finite state machine implementation in Luau
	API based off of https://github.com/kyleconroy/lua-state-machine

	Usage:
	The user keeps track of the FSM's states, events, and transitions.
	
	Create states using `State.state`. Even if two states have the same name, comparing the states
	for equivalence will return false.
	You can keep states in a dictionary so they can be auto-completed:
	```lua
	local State = require(path.to.State)

	local states = {
		idle = State.state("idle"),
		running = State.state("running"),
	}
	
	print(states.idle) --> State.state("idle")
	```
	
	Create events using `State.event`. They're the same deal as with states.
	You can typecast to infer the types of their arguments in FSM functions:
	```lua
	local events = {
		move = State.event("move") :: State.Event<Input.KeyCode>, -- movement key that was pressed
		stop = State.event("stop") :: State.Event<Input.KeyCode>, -- movement key that was released
	}
	```
	
	Transitions are simple dictionaries that describe an event which takes one state to another.
	```lua
	local transitions = {
		{
			event = events.move,
			from = states.idle,
			to = states.running,
		},
		
		-- You can use `State.transition` to define transitions more tersely:
		State.transition(events.stop, states.running, states.idle),
	}
	```
	
	NOTE: The order of the transitions is important. The earlier it's defined, the higher its priority.
	If you have two transitions that trigger on the same event and from the same state, the first one
	defined will be the one that is triggered.
	
	Now that you've fully described the state machine, you can create it:
	```lua
	local machine = State.machine(states, events, transitions)
	```
	
	React to state transitions using `Machine.setOnStateChanged`:
	```lua
	machine.setOnStateChanged(function(entity, event, fromState, toState)
		print(`{event} | Transition from {fromState} to {toState}`)
	end)
	```
	
	State transitions are made using `Machine.processEvent`:
	```lua
	local currentState = states.idle
	currentState = machine.processEvent(events.move) --> move | Transition from idle to running
	```
	-- TODO: rest of docs

	Changelog:
	v0.1.1 (2025-02-12)
	- Notes: Add file information
	v0.1.0 (2024-04-07)
	- Notes: Release
]]

--!strict

local NOOP = function() end

local stateMetatable = {
	__tostring = function(self)
		return `state("{self.name}")`
	end,
}
local eventMetatable = {
	__tostring = function(self)
		return `event("{self.name}")`
	end,
}

type TransitionAction<E, A...> = (entity: E, A...) -> ()
type TransitionPredicate<E, A...> = (entity: E, A...) -> (boolean?)
export type Transition<E, A...> = {
	event: Event<A...>,
	from: State | { State },
	to: State,
	action: TransitionAction<E, A...>,
	predicate: TransitionPredicate<E, A...>,
}
export type TransitionArray<E> = { Transition<E, ...any> }

export type State = { name: string }
export type Event<A...> = {
	name: string,
	_: (A...) -> () -- This funniness is the only way to get generic type inference
}

type BeforeTransitionCallback<E, A...> = (entity: E, event: Event<A...>, from: State, to: State, A...) -> (boolean?)
type AfterTransitionCallback<E, A...> = (entity: E, event: Event<A...>, from: State, to: State, A...) -> ()

export type Machine<E> = {
	processEvents: boolean,

	setOnBeforeEvent: <A...>(event: Event<A...>, callback: BeforeTransitionCallback<E, ...any>?) -> (),
	setOnAfterEvent: <A...>(event: Event<A...>, callback: AfterTransitionCallback<E, ...any>?) -> (),
	setOnLeaveState: (state: State, callback: BeforeTransitionCallback<E, ...any>?) -> (),
	setOnEnterState: (state: State, callback: AfterTransitionCallback<E, ...any>?) -> (),
	setOnStateChanged: (AfterTransitionCallback<E, ...any>?) -> (),
	processEvent: <A...>(entity: E, currentState: State, event: Event<A...>, A...) -> State,
}

local function transition<E, A...>(
	event: Event<A...>,
	from: State | { State },
	to: State,
	action: TransitionAction<E, A...>?,
	predicate: TransitionPredicate<E, A...>?
): Transition<E, A...>
	return {
		event = event,
		from = from,
		to = to,
		action = action or NOOP,
		predicate = predicate or NOOP,
	}
end

local function event(name: string): Event<>
	-- Return a unique table so events with the same name belonging to different state machines will not compare as
	-- equal to each other
	return setmetatable({ name = name } :: any, eventMetatable)
end

local function state(name: string): State
	return setmetatable({ name = name } :: any, stateMetatable)
end

local function machine<E>(
	states: { [string]: State },
	events: { [string]: Event<...any> },
	transitions: { Transition<E, ...any> }
): Machine<E>
	local onBeforeEvents: { [Event<...any>]: BeforeTransitionCallback<E, ...any> } = {}
	local onAfterEvents: { [Event<...any>]: AfterTransitionCallback<E, ...any> } = {}
	local onLeaveStates: { [State]: BeforeTransitionCallback<E, ...any> } = {}
	local onEnterStates: { [State]: AfterTransitionCallback<E, ...any> } = {}

	for _, event in events do
		onBeforeEvents[event] = NOOP
		onAfterEvents[event] = NOOP
	end
	for _, state in states do
		onLeaveStates[state] = NOOP
		onEnterStates[state] = NOOP
	end

	local onStateChanged: AfterTransitionCallback<E, ...any> = NOOP

	local machine = {
		processEvents = true,
	}

	function machine.setOnBeforeEvent<A...>(event: Event<A...>, callback: BeforeTransitionCallback<E, ...any>?)
		onBeforeEvents[event] = callback or NOOP
	end

	function machine.setOnAfterEvent<A...>(event: Event<A...>, callback: AfterTransitionCallback<E, ...any>?)
		onAfterEvents[event] = callback or NOOP
	end

	function machine.setOnLeaveState(state: State, callback: BeforeTransitionCallback<E, ...any>?)
		onLeaveStates[state] = callback or NOOP
	end

	function machine.setOnEnterState(state: State, callback: AfterTransitionCallback<E, ...any>?)
		onEnterStates[state] = callback or NOOP
	end

	function machine.setOnStateChanged(callback: AfterTransitionCallback<E, ...any>?)
		onStateChanged = callback or NOOP
	end

	function machine.processEvent<A...>(entity: E, currentState: State, event: Event<A...>, ...: A...): State
		local newState = currentState

		if not machine.processEvents then
			return newState
		end

		for _, transition in transitions do
			if transition.event ~= event then
				continue
			end
			local transitionFrom = transition.from

			if
				transitionFrom ~= currentState
				and not table.find(transitionFrom, currentState)
				or transition.predicate(entity, ...) == false
			then
				continue
			end

			local toState = transition.to
			local cancelEvent = onBeforeEvents[event](entity, event, currentState, toState, ...)
			if cancelEvent == false then
				break
			end

			local cancelState = onLeaveStates[currentState](entity, event, currentState, toState, ...)
			if cancelState == false then
				break
			end

			transition.action(entity, ...)
			onEnterStates[currentState](entity, event, currentState, toState, ...)
			onAfterEvents[event](entity, event, currentState, toState, ...)
			onStateChanged(entity, event, currentState, toState, ...)
			newState = toState

			-- Stop searching for other transitions once we've found a match
			break
		end

		return newState
	end

	return machine
end

local module = {
	event = event,
	state = state,
	transition = transition,
	machine = machine,
}

return module
