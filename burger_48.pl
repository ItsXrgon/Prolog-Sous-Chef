:- include('KB1.pl').
% :- include('KB2.pl').


% stacked(Ingredient, S)
% True if Ingredient has been stacked in situation S
%
% Arguments:
%   Ingredient: The ingredient to check
%   S: The situation
stacked(Ingredient, result(Action, S)) :-
    % Case 1: The ingredient was just stacked in this action
    Action = stack(Ingredient)
    ;
    % Case 2: The ingredient was already stacked in the previous situation
    stacked(Ingredient, S).

% Base case: Nothing is stacked in the initial situation s0
stacked(_, s0) :- fail.


% all_ingredients_stacked(S)
% True if all required ingredients have been stacked in situation S
%
% Arguments:
%   S: The situation to check
all_ingredients_stacked(S) :-
    stacked(bottom_bun, S),
    stacked(patty, S),
    stacked(lettuce, S),
    stacked(cheese, S),
    stacked(pickles, S),
    stacked(tomato, S),
    stacked(top_bun, S).


% count_stacks(Ingredient, S, Count)
% Counts how many times an ingredient appears in the situation S
%
% Arguments:
%   Ingredient: The ingredient to count
%   S: The situation
%   Count: The number of times the ingredient was stacked
count_stacks(_, s0, 0).

count_stacks(Ingredient, result(stack(Ingredient), S), Count) :-
    count_stacks(Ingredient, S, PrevCount),
    Count is PrevCount + 1.

count_stacks(Ingredient, result(stack(Other), S), Count) :-
    Other \= Ingredient,
    count_stacks(Ingredient, S, Count).


% one_of_each_ingredient(S)
% True if each ingredient appears exactly once in situation S
%
% Arguments:
%   S: The situation to check
one_of_each_ingredient(S) :-
    count_stacks(bottom_bun, S, 1),
    count_stacks(patty, S, 1),
    count_stacks(lettuce, S, 1),
    count_stacks(cheese, S, 1),
    count_stacks(pickles, S, 1),
    count_stacks(tomato, S, 1),
    count_stacks(top_bun, S, 1).


% first_action(S, Action)
% True if Action is the first action taken from the initial situation
%
% Arguments:
%   S: The situation
%   Action: The first action
first_action(result(Action, s0), Action).

first_action(result(_, S), Action) :-
    first_action(S, Action).


% last_action(S, Action)
% True if Action is the last action taken in situation S
%
% Arguments:
%   S: The situation
%   Action: The last action
last_action(result(Action, _), Action).


% stacked_before(Ingredient1, Ingredient2, S)
% True if Ingredient1 was stacked before Ingredient2 in situation S
%
% Arguments:
%   Ingredient1: The ingredient that should be below
%   Ingredient2: The ingredient that should be above
%   S: The situation
stacked_before(Ingredient1, Ingredient2, result(stack(Ingredient2), S)) :-
    stacked(Ingredient1, S),
    !.

stacked_before(Ingredient1, Ingredient2, result(stack(_), S)) :-
    stacked_before(Ingredient1, Ingredient2, S).


% constraints_satisfied(S)
% True if all above/2 constraints from the knowledge base are satisfied
% For each above(Upper, Lower), Upper must have been stacked after Lower
%
% Arguments:
%   S: The situation to check
constraints_satisfied(S) :-
    forall(
        above(Upper, Lower),
        (stacked(Upper, S), stacked(Lower, S), stacked_before(Lower, Upper, S))
    ).


% burgerReady_goal(S)
% The goal predicate that defines a valid burger configuration
%
% Arguments:
%   S: A situation representing a complete valid burger
burgerReady_goal(S) :-
    % Check all ingredients present
    all_ingredients_stacked(S),
    % Check each ingredient exactly once
    one_of_each_ingredient(S),
    % Check bottom_bun is first
    first_action(S, stack(bottom_bun)),
    % Check top_bun is last
    last_action(S, stack(top_bun)),
    % Check all above/2 constraints satisfied
    constraints_satisfied(S).


% build_situation(S)
% Builds a situation by stacking ingredients one at a time
% This generates candidate solutions for IDS to explore
%
% Arguments:
%   S: A situation built from s0
build_situation(s0).

build_situation(result(stack(Ingredient), S)) :-
    build_situation(S),
    member(Ingredient, [bottom_bun, patty, lettuce, cheese, pickles, tomato, top_bun]),
    \+ stacked(Ingredient, S).

% burgerReady(S)
% Main predicate to find a valid burger configuration using IDS
%
% Arguments:
%   S: A situation representing a complete valid burger
burgerReady(S) :-
    ids_burgerReady(S, 1).


% ids_burgerReady(S, Limit)
% Implements iterative deepening search for burgerReady
% Starts with depth limit and increases as needed
%
% Arguments:
%   S: The situation to find
%   Limit: The current depth limit
ids_burgerReady(S, Limit) :-
    % Try to find solution within current depth limit
    call_with_depth_limit(
        (build_situation(S), burgerReady_goal(S)),
        Limit,
        Result
    ),
    % Check if we found a solution or need to go deeper
    (   number(Result) -> true  % Found solution within limit
    ;   Result = depth_limit_exceeded,
        NewLimit is Limit + 1,
        ids_burgerReady(S, NewLimit)  % Try with deeper limit
    ).