:- use_module(internal_api).
:- use_module(leolib) .


go1 :-
    add_node(task, "Wash the car", N1),
    update_node_name(N1, "Wash the Skoda") ,
    add_node_property(N1, mark, "Skoda"),
    add_node_property(N1, color, "gray") ,
    dump(node(N1)) ,
    add_node(task, "Ta hand om bilen", N2),
    add_relation(subtask, N2, N1, "Supertask", "Subtask", _Out_relation_id) .

promptx :-
    forever ,
    write("Vad heter du: ") ,
    get_single_char(A), get_single_char(B), put_char(B), put_char(A) ,
    fail .

prompt :-
    forever ,
    write("Vad heter du: ") ,
    read_string(user_input, "\n", "\t ", _End, String),
    prompt2(String) .

prompt2("quit") :- ! .

prompt2(String) :-
    write(String) , nl ,
    fail .

menu :-
    forever ,
    l_write_list([nl, "Main menu", nl,
                  " 1. Create node", nl,
                  " 2. Select node", nl,
                  " q. Quit", nl,
                  " > "]) ,
    get_single_char(Char),
    atom_char(Selected, Char),
    menu_select(Selected) .

menu_select('q') :- ! . % Quit
menu_select('1') :- % Add node
    l_write_list(["Add node ", nl]) ,
    l_write_list([" Type: "]) , read_string(user_input, "\n", "\t ", _End, Type),
    l_write_list([" Name: "]) , read_string(user_input, "\n", "\t ", _, Name),
    add_node(Type, Name, Id) ,
    l_write_list(["Node ", Id, " created.", nl]),
    fail .
menu_select('2') :- % Select node
    get_all_nodes(All) ,
    node_select_menu(All, Selected_id),
    dump(Selected_id) ,
    fail .

node_select_menu(All, Selected) :-
    l_write_list([nl, "Select a node", nl]),
    list_nodes(All),
    l_write_list([" > "]),
    read_string(user_input, "\n", "\t ", _End, Selected_string) ,
    number_string(Selected, Selected_string) .


list_nodes([]) :- !.
list_nodes([[Type, Name, Id] | Rest]) :-
    l_write_list([Id , ". ", Type, ": ", Name, nl]),
    list_nodes(Rest) .


forever .
forever :- forever .

