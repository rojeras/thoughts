go :-
    write("Starting").

% Base types
node(id, node_type, short_name, relation_list, property_list) .
relation(id, source_id, target_id, relation_type, relation_list, property_list) .
property_types([string("sss"), int(42), float('12,2'), date('2021-07-26')]) .

% Polymorphic methods
add(int(A), int(B), int(C)) :- ! , plus(A, B, C) .
