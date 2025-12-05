:- include('KB1.pl').
% :- include('KB2.pl').

% ===================================================================
% FLUENT: stackedList(List, Situation)
%   - List is the list of ingredients from bottom to top in Situation.
%   - Initial situation: stackedList([], s0).
% ===================================================================

/** Base case: no ingredients initially. */
stackedList([], s0).

/** Successor-State Axiom for stackedList/2
 *
 * Two cases:
 * 1) If the action performed is stack(X), then the new stacked list is
 *    the previous list with X appended (provided action is possible).
 * 2) If the action is something else, the stacked list persists unchanged.
 *
 * This is a proper SSA: it defines stackedList in result(A,S) in terms of
 * stackedList in S and the action A.
 */
stackedList(NewList, result(A, S)) :-
    A = stack(X),
    stackedList(PrevList, S),
    append(PrevList, [X], NewList).

stackedList(List, result(A, S)) :-
    A \= stack(_),
    stackedList(List, S).

% ===================================================================
% ACTION PRECONDITIONS (Poss)
%   poss(stack(X), S) - stacking X on top of the current burger in S is allowed
% ===================================================================

/** poss(stack(X), S)
 *
 * Preconditions:
 *  - X is a valid ingredient.
 *  - bottom_bun must be the first action (i.e., if PrevList == [], X must be bottom_bun).
 *  - No duplicates: X is not already in PrevList.
 *  - top_bun rules: top_bun must be the 7th ingredient (index 6), not earlier.
 *  - Stacking X must not immediately violate any above(Z, X) constraint where Z must be above X
 *    but Z is already in the stack (because stacking X on top would put X above Z, violating above(Z,X)).
 */
poss(stack(X), S) :-
    validIngredient(X),
    stackedList(PrevList, S),
    % bottom bun must be placed first
    (PrevList = [] -> X = bottom_bun ; true),
    % no duplicates
    \+ member(X, PrevList),
    length(PrevList, Len),
    % top_bun only allowed as 7th ingredient (Len = 6 before adding it)
    ((X = top_bun -> Len = 6); (Len = 6 -> X = top_bun); Len < 6),
    % ensure we do not immediately violate above constraints:
    % for any Z where above(Z, X) (Z must be above X), Z must not already be in PrevList
    % because stacking X now would put X above Z (violation).
    \+ ( above(Z, X),
         member(Z, PrevList)
       ).

% ===================================================================
% INGREDIENT DEFINITIONS
% ===================================================================

validIngredient(bottom_bun).
validIngredient(patty).
validIngredient(lettuce).
validIngredient(cheese).
validIngredient(pickles).
validIngredient(tomato).
validIngredient(top_bun).

allIngredients([patty, lettuce, cheese, pickles, tomato]).

% ===================================================================
% VALIDATION PREDICATES (used to check final burger)
% ===================================================================

/** satisfiesAboveConstraints(+StackList)
 *
 * Every above(X,Y) fact from the KB must hold in StackList,
 * i.e., X's index must be greater than Y's index.
 */
satisfiesAboveConstraints(StackList) :-
    forall(above(X, Y), satisfiesAboveConstraint(X, Y, StackList)).

satisfiesAboveConstraint(X, Y, StackList) :-
    nth0(IdxY, StackList, Y),
    nth0(IdxX, StackList, X),
    IdxX > IdxY.

% countOccurrences(Element, List, Count)
countOccurrences(_, [], 0).
countOccurrences(X, [X|T], Count) :-
    countOccurrences(X, T, CT),
    Count is CT + 1.
countOccurrences(X, [Y|T], Count) :-
    X \= Y,
    countOccurrences(X, T, Count).

hasAllRequiredIngredients(StackList) :-
    allIngredients(Req),
    forall(member(I, Req), countOccurrences(I, StackList, 1)),
    countOccurrences(bottom_bun, StackList, 1),
    countOccurrences(top_bun, StackList, 1).

hasCorrectBunOrder(StackList) :-
    StackList = [bottom_bun | _],
    last(StackList, top_bun).

isValidBurger(StackList) :-
    hasCorrectBunOrder(StackList),
    hasAllRequiredIngredients(StackList),
    satisfiesAboveConstraints(StackList).

% ===================================================================
% REACHABILITY
%   reachable(S) - S is reachable from s0 using poss/2 and stack/1 actions
%   This is defined recursively; IDS will limit depth to avoid non-termination.
% ===================================================================
reachable(s0).
reachable(result(stack(X), S)) :-
    reachable(S),
    poss(stack(X), S).

% ===================================================================
% burgerReady: search for or verify a situation S that is a valid complete burger
% Uses IDS (iterative deepening) with call_with_depth_limit/3 to guarantee completeness.
% ===================================================================

burgerReady(S) :-
    burgerReadyIDS(S, 1).

burgerReadyIDS(S, Limit) :-
    ( call_with_depth_limit(burgerReadyDirect(S), Limit, Result),
      number(Result)
    );
    ( call_with_depth_limit(burgerReadyDirect(S), Limit, Result),
      Result = depth_limit_exceeded,
      Next is Limit + 1,
      burgerReadyIDS(S, Next)
    ).

burgerReadyDirect(S) :-
    reachable(S),
    stackedList(StackList, S),
    isValidBurger(StackList).
