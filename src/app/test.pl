:- use_module(internal_api).


go1 :-
    add_node(task, "Wash the car", N1),
    update_node_name(N1, "Wash the Skoda") ,
    add_node_property(N1, mark, "Skoda"),
    add_node_property(N1, color, "gray") ,
    dump(node(N1)) ,
    add_node(task, "Ta hand om bilen", N2),
    add_relation(subtask, N2, N1, "Supertask", "Subtask", _Out_relation_id) .

prompt_add_node :-
    write("Node type: "), readl




