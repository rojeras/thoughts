:- module(internal_api, [
              add_node/3,
              add_node_property/3,
              add_relation/6,
              dump/1,
              get_node/3,
              get_all_nodes/1,
              update_node_name/2
          ]) .

:- dynamic(db_node/7) .
:- dynamic(db_relation/10) .

:- use_module(leolib).

% ================================================================================================================================

/**
 * External Prolog API to nodes and relations
 */

load_all :- impl_load_all.
% -----------------------------------------------------------------------
get_node(Type, Name, Id) :- impl_get(node(Id), Type, Name) .

get_all_nodes(List) :- findall([Type, Name, Id], get_node(Type, Name, Id), List) .

add_node(Type, Name, Id) :- impl_add(node(Id), Type, Name) .

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
get_node_created_timestamp(Id, Timestamp) :- impl_get_timestamp(node(Id), created, Timestamp) .
get_node_modified_timestamp(Id, Timestamp) :- impl_get_timestamp(node(Id), modified, Timestamp) .
% -----------------------------------------------------------------------
add_relation(Relation_type, Parent_node_id, Child_node_id, Parent_label, Child_label, Id) :-
    impl_add(relation(Id), Relation_type, Parent_node_id, Child_node_id, Parent_label, Child_label) .


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
dump(Id) :- impl_dump(node(Id)) .



% ================================================================================================================================
% -----------------------------------------------------------------------
% The goal is to have the internal API polomorphic. No type in the
% predicate names.

impl_load_all :-
    remove_all ,
    consult("thoughts.db") .

impl_get(node(Id), Type, Name) :-
    db_node(Id, _Ver, Type, Name, _Property_list, _Timestamp_list, active ) .

impl_get(relation(Id), Rtype, Pid, Cid, Plabel, Clabel ) :-
    db_relation(Id, 0, Pid, Cid, Rtype, Plabel, Clabel, _Props, _Timestamps, active) .


% -----------------------------------------------------------------------

impl_get_property_names(node(Id), List_of_property_names) :-
    db_node(Id, _Ver, _Type, _Name, Property_list, _Timestamp_list, active ) ,
    extract_property_names(Property_list, List_of_property_names) .

impl_get_property_names(relation(Id), List_of_property_names) :-
    db_relation(Id, _Ver, _Pid, _Cid, _Rtype, _Plabel, _Clabel, Property_list, _Timestamp_list, active) ,
    extract_property_names(Property_list, List_of_property_names) .

extract_property_names([], [] ) :- ! .
extract_property_names([property(Name, _Value) | Restof_props], [Name | Restof_names]) :-
    extract_property_names(Restof_props, Restof_names) .

% -----------------------------------------------------------------------

impl_get_property_value(node(Id), Property_name, Value) :-
    db_node(Id, _Ver, _Type, _Name, Property_list, _Timestamp_list, active ) ,
    extract_property_value(Property_name, Property_list, Value) .

impl_get_property_value(relation(Id), Property_name, Value) :-
    db_relation(Id, _Ver, _Pid, _Cid, _Rtype, _Plabel, _Clabel, Property_list, _Timestamps, active) ,
    extract_property_value(Property_name, Property_list, Value) .

extract_property_value(_Name, [], _Value ) :- ! , fail.
extract_property_value(Name, [property(Name, Value) | _Restof_props], Value) :- ! .
extract_property_value(Name, [property(_Name, _Value) | Restof_props], Value) :-
    extract_property_value(Name, Restof_props, Value) .

% -----------------------------------------------------------------------

impl_add(node(Id), Type, Name) :-
    max_node_id(Max) ,
    Id is Max + 1 ,
    current_timestamp(Timestamp) ,
    assertz(db_node(Id, 0, Type, Name, [], [Timestamp], active )) .

impl_add(relation(_Id), Rtype, Pid, Cid, _, _) :-
    impl_get(relation(_), Rtype, Pid, Cid, _Plabel, _Clabel ) ,
    ! ,
    fail . % Relation already exist

impl_add(relation(Id), Rtype, Pid, Cid, Plabel, Clabel) :-
    impl_get(node(Pid), _Type, _Name) ,
    impl_get(node(Cid), _, _) ,
    max_rel_id(Max) ,
    Id is Max + 1,
    current_timestamp(Timestamp) ,
    assertz(db_relation(Id, 0, Pid, Cid, Rtype, Plabel, Clabel, [], [Timestamp], active)).

% -----------------------------------------------------------------------

impl_add_property(node(Id), Property_name, Property_value) :-
    db_node(Id, Ver, Type, Name, Property_list, Timestamp_list, active ) ,
    \+ member(property(Property_name, _), Property_list), % Ensure the proprety does not already exist
    impl_deactivate(node(Id)) ,
    New_ver is Ver + 1 ,
    current_timestamp(Timestamp) ,
    assertz(db_node(Id, New_ver, Type, Name, [property(Property_name, Property_value) | Property_list], [Timestamp | Timestamp_list], active )) .

impl_add_property(relation(Id), Property_name, Property_value) :-
    db_relation(Id, Ver, Pid, Cid, Rtype, Plabel, Clabel, Property_list, Timestamp_list, active) ,
    \+ member(property(Property_name, _), Property_list), % Ensure the proprety does not already exist
    impl_deactivate(relation(Id)) ,
    New_ver is Ver + 1 ,
    current_timestamp(Timestamp) ,
    assertz(db_relation(Id, New_ver, Pid, Cid, Rtype, Plabel, Clabel, [property(Property_name, Property_value) | Property_list], [Timestamp | Timestamp_list], active )) .

% -----------------------------------------------------------------------

impl_remove_property(node(Id), Property_name) :-
    db_node(Id, Ver, Type, Name, Property_list, Timestamp_list, active ) ,
    member(property(Property_name, _) , Property_list) ,
    subtract(Property_list, [property(Property_name, _)], Updated_property_list) ,
    impl_deactivate(node(Id)) ,
    New_ver is Ver + 1 ,
    current_timestamp(Timestamp) ,
    assertz(db_node(Id, New_ver, Type, Name, Updated_property_list, [Timestamp | Timestamp_list], active )) .

impl_remove_property(relation(Id), Property_name) :-
    db_relation(Id, Ver, Pid, Cid, Rtype, Plabel, Clabel, Property_list, Timestamp_list, active) ,
    member(property(Property_name, _) , Property_list) ,
    subtract(Property_list, [property(Property_name, _)], Updated_property_list) ,
    impl_deactivate(relation(Id)) ,
    New_ver is Ver + 1 ,
    current_timestamp(Timestamp) ,
    assertz(db_relation(Id, New_ver, Pid, Cid, Rtype, Plabel, Clabel, Updated_property_list, [Timestamp | Timestamp_list], active )) .

% -----------------------------------------------------------------------

impl_update_name(node(Id), NewName) :-
    db_node(Id, Ver, Type, _OldName, Property_list, Timestamp_list, active ) ,
    impl_deactivate(node(Id)) ,
    New_ver is Ver + 1 ,
    current_timestamp(Timestamp) ,
    assertz(db_node(Id, New_ver, Type, NewName, Property_list, [Timestamp | Timestamp_list], active )) .

impl_update_names(relation(Id), New_plabel, New_clabel) :-
    db_relation(Id, Ver, Pid, Cid, Rtype, _Plabel, _Clabel, Property_list, Timestamp_list, active) ,
    impl_deactivate(relation(Id)) ,
    New_ver is Ver + 1 ,
    current_timestamp(Timestamp) ,
    assertz(db_relation(Id, New_ver, Pid, Cid, Rtype, New_plabel, New_clabel, Property_list, [Timestamp | Timestamp_list], active )) .

% -----------------------------------------------------------------------

impl_get_timestamp(node(Id), created, Timestamp) :-
    db_node(Id, _Ver, _Type, _Name, _Property_list, Timestamp_list, active ) ,
    last(Timestamp_list, Timestamp) .

impl_get_timestamp(node(Id), modified, Timestamp) :- db_node(Id, _Ver, _Type, _Name, _Property_list, [Timestamp | _], active ) .


current_timestamp(TimeStamp) :-
    get_time(T),
    stamp_date_time(T, TimeStamp, 'UTC').

% -----------------------------------------------------------------------

impl_remove(node(Id)) :-
    % Also need to remove relations
    db_node(Id, Ver, Type, Name, Property_list, Timestamp_list, active ) ,
    impl_deactivate(node(Id)) ,
    New_ver is Ver + 1 ,
    current_timestamp(Timestamp) ,
    assertz(db_node(Id, New_ver, Type, Name, Property_list, [Timestamp | Timestamp_list], removed )) .

impl_remove(relation(Id)) :-
    db_relation(Id, Ver, Pid, Cid, Rtype, Plabel, Clabel, Property_list, Timestamp_list, active ) ,
    impl_deactivate(relation(Id)) ,
    New_ver is Ver + 1 ,
    current_timestamp(Timestamp) ,
    assertz(db_relation(Id, New_ver, Pid, Cid, Rtype, Plabel, Clabel, Property_list, [Timestamp | Timestamp_list], removed)).


% -----------------------------------------------------------------------

impl_deactivate(node(Id)) :-
     db_node(Id, Ver, Type, Name, Property_list, Timestamp_list, active ) ,
     retractall(db_node(Id, Ver, Type, Name, Property_list, Timestamp_list, active )) ,
     assertz(db_node(Id, Ver, Type, Name, Property_list, Timestamp_list, inactive )) .

impl_deactivate(relation(Id)) :-
     db_relation(Id, Ver, Pid, Cid, Rtype, Plabel, Clabel, Property_list, Timestamp_list, active ) ,
     retractall(db_relation(Id, Ver, Pid, Cid, Rtype, Plabel, Clabel, Property_list, Timestamp_list, active )) ,
     assertz(db_relation(Id, Ver, Pid, Cid, Rtype, Plabel, Clabel, Property_list, Timestamp_list, inactive )) .


% -----------------------------------------------------------------------

max_node_id(Max) :-
    findall(Id, db_node(Id, _, _, _, _, _, _), Id_list) ,
    max_list(Id_list, Max),
    !.
max_node_id(0) .

max_rel_id(Max) :-
    findall(Id, db_relation(Id, _, _, _, _, _, _, _, _, _), Id_list) ,
    max_list(Id_list, Max),
    !.
max_rel_id(0) .

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

remove_all :-
    retractall(db_node(_, _, _, _, _, _, _ )) ,
    retractall(db_relation(_, _, _, _, _, _, _, _, _, _)) .


% =======================================================================


impl_dump(node(Id)) :-
    get_node(Type, Name, Id) ,
    l_write_list(["Node dump.", nl, " Id: ", Id, nl, " Type: ", Type, nl, " Name: ", Name, nl, " Properties:", nl ]) ,
    dump_properties(node(Id)),
    dump_timestamps(node(Id)) .

dump_properties(node(Id)) :-
    get_node_property_names(Id, Property_name_list) ,
    dump_node_properties2(Id, Property_name_list) .

dump_node_properties2(_Id, []) :- ! .

dump_node_properties2(Id, [Name | Rest_of_names]) :-
    get_node_property_value(Id, Name, Value) ,
    l_write_list(["   ", Name ," : ", Value , nl]),
    dump_node_properties2(Id, Rest_of_names) .

dump_timestamps(node(Id)) :-
    get_node_created_timestamp(Id, C_timestamp),
    l_write_list([" Created: ", C_timestamp, nl]) ,
    get_node_modified_timestamp(Id, M_timestamp),
    l_write_list([" Last modified: ", M_timestamp, nl]) .








