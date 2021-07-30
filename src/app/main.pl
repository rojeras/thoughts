:- dynamic(node/5) .
:- dynamic(relation/7) .

:- use_module(leolib).

go :-
    write("Starting me").

/*
% Base types
% All modification stored, all history available in the db. Also all access time stamps.
node(id, node_type, short_name, property_list, meta(version, status,timestamps([deleted, accessed, accessed, modified, accessed, created]) .
relation(id, source_id, target_id, relation_type, relation_list,
property_list) . property_types([string("sss"), int(42), float('12,2'),
date('2021-07-26')]) .

% Polymorphic methods
add(int(A), int(B), int(C)) :- ! , plus(A, B, C) .
*/

node(
    1,
    task,
    string("Fixa kanoterna"),
    [prop(prio, int(42))],
    meta(1, created, timestamps(["2021-07-28 12:08:16", "..."] ))
    ) .


node(
    1,
    task,
    string("Fixa kanoterna"),
    [prop(prio, int(42))],
    meta(2, modified, timestamps(["2021-07-29 12:08:16", "...", "..."] ))
    ) .

node(
    2,
    task,
    string("Köp vajer"),
    [],
    meta(
        timestamp("2021-07-28 12:08:17"),
        active
    )
    ) .

relation(
    1,
         1,
         2,
         parent_child,
         "Parent task",
         "Subtask",
         meta(
             active,
             timestamp("2021-07-28 12:08:16")
         )
       ) .



node_types([task]) .
relation_types([parent_child]) .
primitive_types(
    [
     string,
     timestamp,
     prio
    ]
) .

% -----------------------------------------------------------------------

load_all :-
    remove_all ,
    consult("thoughts.db") ,
    node_max_id(Max) ,
    write(Max) ,
    l_counter_set(node_id_max, Max ).

node_max_id(Max) :-
    findall(Id, node(Id, _, _, _, _), Id_list) ,
    max_list(Id_list, Max) .

% -----------------------------------------------------------------------

store_all :-
    open("thoughts.db", write, Stream, []) ,
    store_nodes(Stream) ,
    store_relations(Stream) ,
    close(Stream).

store_nodes(Stream) :-
    node(A, B, C, D, E) ,
    writeq(Stream, node(A, B, C, D, E)) ,
    write(Stream, " ."),
    nl(Stream) ,
    fail.
store_nodes(_) .

store_relations(Stream) :-
    relation(A, B, C, D, E, F, G) ,
    writeq(Stream, relation(A, B, C, D, E, F, G)) ,
    write(Stream, " ."),
    nl(Stream) ,
    fail.
store_relations(_) .

% -----------------------------------------------------------------------

remove_all :-
    retractall(node(_, _, _, _, _ )) ,
    retractall(relation(_, _, _, _, _, _, _)) .










