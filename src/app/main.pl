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
*/

go1 :-
    add_node(task, "Wash the car", N1),
    update_node_name(N1, "Wash the Skoda") ,
    add_node_property(N1, mark, "Skoda"),
    add_node_property(N1, color, "gray") ,
    dump(node(N1)) .

% -----------------------------------------------------------------------
dump(node(Id)) :-
    get_node(Id, Type, Name) ,
    l_write_list(["Node dump.", nl, " Id: ", Id, nl, " Type: ", Type, nl, " Name: ", Name, nl, " Properties:", nl ]) ,
    dump_properties(node(Id)) .


dump_properties(node(Id)) :-
    get_node_property_names(Id, Property_name_list) ,
    dump_node_properties2(Id, Property_name_list) .

dump_node_properties2(_Id, []) :- ! .
dump_node_properties2(Id, [Name | Rest_of_names]) :-
    get_node_property_value(Id, Name, Value) ,
    l_write_list(["   ", Name ," : ", Value , nl]),
    dump_node_properties2(Id, Rest_of_names) .

% =======================================================================
/**
 * External Prolog API to nodes and relations
 */

load_all :- impl_load_all.
% -----------------------------------------------------------------------
get_node(Id, Type, Name) :- impl_get(node(Id), Type, Name) .

add_node(Type, Name, Id) :- impl_add_node(node(Id), Type, Name) .

get_node_property_names(Id, List_of_property_names) :- impl_get_property_names(node(Id), List_of_property_names) .
get_node_property_value(Id, Property_name, Value) :- impl_get_property_value(node(Id), Property_name, Value) .

% -----------------------------------------------------------------------
remove_node(Node_id) :- impl_remove(node(Node_id)) .
% -----------------------------------------------------------------------
update_node_name(Node_id, Name) :- impl_update_name(node(Node_id), Name) .
% -----------------------------------------------------------------------
add_node_property(Node_id, Property_name, Property_value) :- impl_add_property(node(Node_id), Property_name, Property_value) .
% -----------------------------------------------------------------------
remove_node_property(Node_id, Property_name) :- impl_remove_property(node(Node_id), Property_name) .
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
% The goal is to have the internal API polomorphic. No type in the
% predicate names.

impl_load_all :-
    remove_all ,
    consult("thoughts.db") .

impl_get(node(Id), Type, Name) :- db_node(Id, _Ver, Type, Name, _Property_list, _Timestamp_list, active ) .

impl_get_property_names(node(Id), List_of_property_names) :-
    db_node(Id, _Ver, _Type, _Name, Property_list, _Timestamp_list, active ) ,
    extract_property_names(Property_list, List_of_property_names) .


extract_property_names([], [] ) :- ! .
extract_property_names([property(Name, _Value) | Restof_props], [Name | Restof_names]) :-
    extract_property_names(Restof_props, Restof_names) .

impl_get_property_value(node(Id), Property_name, Value) :-
    db_node(Id, _Ver, _Type, _Name, Property_list, _Timestamp_list, active ) ,
    extract_property_value(Property_name, Property_list, Value) .

extract_property_value(_Name, [], _Value ) :- ! , fail.
extract_property_value(Name, [property(Name, Value) | _Restof_props], Value) :- ! .
extract_property_value(Name, [property(_Name, _Value) | Restof_props], Value) :-
    extract_property_value(Name, Restof_props, Value) .

impl_add_node(node(Id), Type, Name) :-
    max_node_id(Max) ,
    Id is Max + 1 ,
    current_timestamp(Timestamp) ,
    assertz(db_node(Id, 0, Type, Name, [], [Timestamp], active )) .

impl_add_property(node(Id), Property_name, Property_value) :-
    db_node(Id, Ver, Type, Name, Property_list, Timestamp_list, active ) ,
    \+ member(property(Property_name, _), Property_list), % Ensure the proprety does not already exist
    deactivate(node(Id)) ,
    New_ver is Ver + 1 ,
    current_timestamp(Timestamp) ,
    assertz(db_node(Id, New_ver, Type, Name, [property(Property_name, Property_value) | Property_list], [Timestamp | Timestamp_list], active )) .

impl_remove_property(node(Id), Property_name) :-
    db_node(Id, Ver, Type, Name, Property_list, Timestamp_list, active ) ,
    member(property(Property_name, _) , Property_list) ,
    subtract(Property_list, [property(Property_name, _)], Updated_property_list) ,
    deactivate(node(Id)) ,
    New_ver is Ver + 1 ,
    current_timestamp(Timestamp) ,
    assertz(db_node(Id, New_ver, Type, Name, Updated_property_list, [Timestamp | Timestamp_list], active )) .


impl_update_name(node(Id), NewName) :-
    db_node(Id, Ver, Type, _OldName, Property_list, Timestamp_list, active ) ,
    deactivate(node(Id)) ,
    New_ver is Ver + 1 ,
    current_timestamp(Timestamp) ,
    assertz(db_node(Id, New_ver, Type, NewName, Property_list, [Timestamp | Timestamp_list], active )) .

impl_remove(node(Id)) :-
    % Also need to remove relations
    db_node(Id, Ver, Type, Name, Property_list, Timestamp_list, active ) ,
    deactivate(node(Id)) ,
    New_ver is Ver + 1 ,
    current_timestamp(Timestamp) ,
    assertz(db_node(Id, New_ver, Type, Name, Property_list, [Timestamp | Timestamp_list], removed )) .


deactivate(node(Id)) :-
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
    db_relation(A, B, C, D, E, F, G, H, I, J) ,
    writeq(Stream, db_relation(A, B, C, D, E, F, G, H, I, J)) ,
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









