:- dynamic(db_node/7) .
:- dynamic(db_relation/10) .

:- use_module(leolib).

go :-
    write("Starting me again").

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
/*
=======================================================================
Definition of DB terms. These are made persistant.
=======================================================================

db_node(
    Id,
    Version,
    Typek,
    Name,
    Property_list,
    Timestamp_list ,
    Status
    ) .

db_relation(
    Id,
    Version,
    Parent_node_id,
    Child_node_id,
    Relation_type,
    Parent_node_label,
    Child_node_label,
    Property_list,
    Timestamp_list,
    Status
   ) .
=========================================================================
*/

/*
db_node(
    1,
    2,
    task,
    string("Fixa kanoterna"),
    [prop(prio, int(42))],
    ["2021-07-29 12:08:16", "...", "..."] ,
    active
    ) .

db_node(
    2,
    1,
    task,
    string("Fixa sss"),
    [prop(prio, int(42))],
    ["2021-07-29 12:08:16", "...", "..."] ,
    deleted
    ) .
*/
db_relation(
    1, % Id
    2, % Version
    1, % Parent node id
    2, % Child node id
    parent_child, % Relation type
    "Parent task", % Parent node label in relation
    "Subtask", % Child node label in relation
    [prop(prio, int(42))], % Properties
    ["2021-07-29 12:08:16", "...", "..."] , % Time stamps
    active % status
   ) .


% -----------------------------------------------------------------------
%

% =======================================================================
/**
 * External Prolog API to nodes and relations
 */

load_all :- impl_load_all.
% -----------------------------------------------------------------------
add_node(Type, Name, Id) :- impl_add_node(Type, Name, Id) .

% -----------------------------------------------------------------------
remove_node(Node_id) :- impl_remove_node(Node_id) .
% -----------------------------------------------------------------------
update_node_name(_Node_id, _Name) .
% -----------------------------------------------------------------------
add_node_property(Node_id, Property_name, Property_value) :- impl_add_node_property(Node_id, Property_name, Property_value) .
% -----------------------------------------------------------------------
remove_node_property(_Node_id, _Property_name) .
% -----------------------------------------------------------------------
add_relation(_Relation_type, _Parent_node_id, _Child_node_id, _Parent_label, _Child_label, _Out_relation_id) .
remove_relation(_In_relation_id) .
add_relation_property(_Node_id, _Property_name, _Property_value) .
% -----------------------------------------------------------------------
remove_relation_property(_Node_id, _Property_name) .
% -----------------------------------------------------------------------
get_node_types(_Type_list) .
get_relation_types(_Type_list) .
% -----------------------------------------------------------------------
start_transaction . % Save current DB to temp file
commit . % Save the db to file.
rollback . % Re-load temp file.
% -----------------------------------------------------------------------


% =======================================================================
% -----------------------------------------------------------------------
%

impl_load_all :-
    remove_all ,
    consult("thoughts.db") .

impl_add_node(Type, Name, Id) :-
    max_node_id(Max) ,
    Id is Max + 1 ,
    current_timestamp(Timestamp) ,
    assertz(db_node(Id, 0, Type, Name, [], [Timestamp], active )) .

impl_add_node_property(Id, Property_name, Property_value) :-
    db_node(Id, Ver, Type, Name, Property_list, Timestamp_list, active ) ,
    deactivate_node(Id) ,
    New_ver is Ver + 1 ,
    current_timestamp(Timestamp) ,
    assertz(db_node(Id, New_ver, Type, Name, [property(Property_name, Property_value) | Property_list], [Timestamp | Timestamp_list], active )) .

impl_remove_node(Id) :-
    % Also need to remove relations
    db_node(Id, Ver, Type, Name, Property_list, Timestamp_list, active ) ,
    deactivate_node(Id) ,
    New_ver is Ver + 1 ,
    current_timestamp(Timestamp) ,
    assertz(db_node(Id, New_ver, Type, Name, Property_list, [Timestamp | Timestamp_list], removed )) .


deactivate_node(Id) :-
     db_node(Id, Ver, Type, Name, Property_list, Timestamp_list, active ) ,
     retractall(db_node(Id, Ver, Type, Name, Property_list, Timestamp_list, active )) ,
     assertz(db_node(Id, Ver, Type, Name, Property_list, Timestamp_list, inactive )) .

/*
impl_remove_node(Node_id) :-
    remove_all_relations_for_node(Node_id) ,
    remove_node(Node_id).

remove_all_relations_for_node(Node_id) :-
    db_
*/
max_node_id(Max) :-
    findall(Id, db_node(Id, _, _, _, _, _, _), Id_list) ,
    max_list(Id_list, Max) .
max_node_id(0) .

% -----------------------------------------------------------------------

store_all :-
    open("thoughts.db", write, Stream, []) ,
    store_nodes(Stream) ,
    store_relations(Stream) ,
    close(Stream).

store_nodes(Stream) :-
    db_node(A, B, C, D, E, F, G) ,
    writeq(Stream, db_node(A, B, C, D, E, F, G)) ,
    write(Stream, " ."),
    nl(Stream) ,
    fail.
store_nodes(_) .

store_relations(Stream) :-
    db_relation(A, B, C, D, E, F, G) ,
    writeq(Stream, db_relation(A, B, C, D, E, F, G)) ,
    write(Stream, " ."),
    nl(Stream) ,
    fail.
store_relations(_) .
% -----------------------------------------------------------------------

current_timestamp(TimeStamp) :-
    get_time(T),
    stamp_date_time(T, TimeStamp, 'UTC').

remove_all :-
    retractall(db_node(_, _, _, _, _, _, _ )) ,
    retractall(db_relation(_, _, _, _, _, _, _, _, _, _)) .


% =======================================================================








