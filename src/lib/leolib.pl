:- module(leolib, [
	      l_common_prefix/2,
	      l_counter_add/2,
	      l_counter_get/2,
	      l_counter_set/2,
	      l_counter_inc/2,
	      l_counter_dec/2,
	      l_counter_remove/1,
	      l_current_date/1,
	      l_current_os/1,
	      l_current_time/1,
	      l_erase_all/1,
	      l_erase_all/2,
	      l_file_date_time/3,
	      l_get_date_time/7,
	      l_get_hostname/2,
	      l_html_write/1,
	      l_html_write/2,
	      l_load_dom_file/2,
	      l_load_dom_http/2,
	      l_ls/2,
	      l_path_to_rpath/2,
	      l_read_file_to_list/2,
	      l_read_file_to_list/3,
	      l_read_stream_to_list/2,
	      l_remove_characters/3,
	      l_set_trace_lvl/1,
	      l_strip_blanks/2,
	      l_strip_leading_chars/3,
	      l_strip_trailing_chars/3,
	      l_trace_lvl/1,
	      l_type_check/2,
	      l_urlencode/2,
	      l_write_file/2,
	      l_write_list/1,
	      l_write_list/2,
	      l_write_trace/2,
	      l_write_trace/3,
	      lNotequal/2
	  ]).

:- use_module(library(http/http_open)).


/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
LEO Prolog library
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

/* ========================================================================
Global settings
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
%:- initialization(l_set_trace_lvl(2)) .

/* ======================================================================
Write to terminal or file
========================================================================= */

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Predicate to do multiple writes and nl in one go
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
l_write_file(terminal, Text) :-
    ! ,
    l_write_list(Text) .

l_write_file(FileName, Text) :-
    open(FileName, append, Stream ) ,
    l_write_list(Stream, Text) ,
    close(Stream) .

% ------------------------------------------------------------------------

l_write_list(Text) :-
	l_write_list(user_output, Text).

l_write_list(Stream, Text) :-
	write_list(Stream, Text, '', '').

write_list(_, [], _, _) :- ! .

write_list(Stream, [nl|Rest], Before, After) :-
	nl(Stream) ,
	write_list(Stream, Rest, Before, After) ,
	! .

write_list(Stream, [Stuff|Rest], Before, After) :-
	write(Stream, Before) ,
	write(Stream, Stuff) ,
	write(Stream, After) ,
	write_list(Stream, Rest, Before, After) .

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Write indented with start and end markers
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

write_indent(Text, Indent) :-
	l_write_spaces(Indent),
	l_remove_characters(Text, [end_of_line], Text2),
	write('>'), write(Text2), write('<'),
	nl .
% ----------- Write a number of spaces
l_write_spaces(X) :-
	l_write_spaces(X, user_output) .

l_write_spaces(X, _Stream) :-
	X < 1 ,
	! .

l_write_spaces(X, Stream) :-
	write(Stream, ' ') ,
	Y = X-1 ,
	l_write_spaces(Y, Stream) .


/* ========================================================================
String management
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Remove characters, including special charactes, from an atom
CharacterList should be a list of atom characters or special chars
according to the third clause.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
l_remove_characters(Text, CharacterList, OutText) :-
	atom_codes(Text, TextList),
	remove_characters2(TextList, CharacterList, TextList2),
	atom_codes(OutText, TextList2) .

remove_characters2([], _, [] ) :- ! .

% This clause manage special characters, like end_of_line. More can be
% added below.
remove_characters2([H|T], CharList, T2 ) :-
	member(Special, [end_of_line]) ,
	member(Special, CharList),
	char_type(H, Special) ,
	! ,
	remove_characters2(T, CharList, T2) .

% Ordinary characters
remove_characters2([H|T], CharList, T2 ) :-
	member(C, CharList),
	char_code(C, H) ,
	! ,
	remove_characters2(T, CharList, T2) .

remove_characters2([H|T], CharList, [H|T2]) :-
	remove_characters2(T, CharList, T2) .


/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Strip leading or trailing chars does just that.
Char should be a single atom character
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
l_strip_blanks(Text1, Text4) :-
	l_strip_leading_chars(Text1, '\t',  Text2) , % Also remove leading tabs
	l_strip_leading_chars(Text2, ' ',  Text3) ,
	l_strip_trailing_chars(Text3, ' ', Text4) .

l_strip_trailing_chars(Text, Char, Text2) :-
	char_code(Char, Code),
	atom_codes(Text, TextList),
	reverse(TextList, TextList2) ,
	strip_leading_chars2(TextList2, Code, TextList3),
	reverse(TextList3, TextList4) ,
	atom_codes(Text2, TextList4) .

l_strip_leading_chars(Text, Char, Text2) :-
	char_code(Char, Code) ,
	atom_codes(Text, TextList),
	strip_leading_chars2(TextList, Code, TextList2),
	atom_codes(Text2, TextList2) .

strip_leading_chars2([], _, []) :- ! .

strip_leading_chars2([Code|Rest], Code, Rest2) :-
	! ,
	strip_leading_chars2(Rest, Code, Rest2) .

strip_leading_chars2(List, _, List) :-  !.


/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Strip leading or trailing chars until a certain character is encounterd
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
strip_leading_until(Text, StripedText, Char) :-
	atom_chars(Text, TextList),
	strip_leading_until2(TextList, StripedList, Char) ,
	atom_chars(StripedText, StripedList) .

strip_leading_until2([], [], _Char) :- !.

strip_leading_until2([Char|Rest] ,  Rest , Char) :- ! .

strip_leading_until2([_First|Rest] ,  Rest2 , Char) :-
	strip_leading_until2(Rest, Rest2, Char) .

strip_trailing_until(Text, Text4, Char) :-
	reverse_atom(Text, Text2),
	strip_leading_until(Text2, Text3, Char),
	reverse_atom(Text3, Text4) .

reverse_atom(Text, Text2) :-
	atom_chars(Text, TextList) ,
	reverse(TextList, TextList2) ,
	atom_chars(Text2, TextList2) .


/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Extract common substring from list
Input is a list of strings
Output is the longest substring of the common beginnings of the
strings. ['abcdef', 'abqgr'] would return 'ab'
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
l_common_prefix([] , '') :- ! .
l_common_prefix([S1] , S1) :- ! .
l_common_prefix([S1, S2 | Rest] , Prefix) :-
	common_prefix(S1, S2, SPref),
	l_common_prefix( [SPref | Rest], Prefix) .

common_prefix(S1, S2, CommonPrefix) :-
	atom(S1),
	atom(S2) ,
	atom_chars(S1, S1L),
	atom_chars(S2, S2L),
	common_prefix2(S1L, S2L, CPL),
	! ,
	atom_chars(CommonPrefix, CPL).

common_prefix2([] , _L2 , [] ) :- ! .

common_prefix2(_L1 , [] , [] ) :- ! .


common_prefix2([Char | Rest1], [Char| Rest2], [Char | RestCommon] ) :-
	! ,
	common_prefix2( Rest1 , Rest2, RestCommon) .

common_prefix2( _L1, _L2, [] ) .

/* ========================================================================
Type checking
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

l_type_check(Term, var) :- var(Term) , ! .
l_type_check(Term, integer) :- integer(Term) , ! .
l_type_check(Term, float) :- float(Term) , ! .
l_type_check(Term, rational) :- rational(Term) , ! .
l_type_check(Term, atom) :- atom(Term) , ! .
l_type_check(Term, string) :- string(Term) , ! .
l_type_check(Term, functor) :- functor(Term, _, _) , ! .

/* ========================================================================
Database predicates
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

l_erase_all(Key) :-
	nonvar(Key),
	l_erase_all(Key, _Fact) .

l_erase_all(Key, Fact) :-
	nonvar(Key),
	recorded(Key, Fact , Reference) ,
	erase(Reference) ,
	fail.

l_erase_all(_,_) .


%counter(Func, Countername, Value)
l_counter_get(CounterName, Value) :-
	recorded(l_counter, counter(CounterName, Value)) .

l_counter_remove(CounterName) :-
	l_erase_all(l_counter, counter(CounterName, _)) .

l_counter_set(CounterName, Value) :-
	nonvar(CounterName),
	nonvar(Value),
	l_counter_remove(CounterName) ,
	recordz(l_counter, counter(CounterName, Value)).

l_counter_inc(CounterName, NewValue) :-
	nonvar(CounterName),
	l_counter_get(CounterName, Value) ,
	! ,
	NewValue is Value + 1 ,
	l_counter_set(CounterName, NewValue ).

l_counter_inc(CounterName, 0) :-
	l_counter_set(CounterName, 0) .

l_counter_add(CounterName, AddValue) :-
	nonvar(CounterName),
	l_counter_get(CounterName, Value) ,
	! ,
	NewValue is Value + AddValue ,
	l_counter_set(CounterName, NewValue ).

l_counter_dec(CounterName, NewValue) :-
	nonvar(CounterName),
	l_counter_get(CounterName, Value) ,
	NewValue is Value - 1 ,
	l_counter_set(CounterName, NewValue ).


/* ========================================================================
I/O predicates
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Read a file
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

l_read_file_to_list(File, Lines) :-
	l_read_file_to_list(File, Lines, []) .

l_read_file_to_list(File, Lines, Options) :-
	exists_file(File),
	open(File, read, Stream, Options),
	! ,
	l_read_stream_to_list(Stream,Lines),
	! ,
	close(Stream) .

l_read_file_to_list(File, _Lines, _Options) :-
	l_write_trace(['** Error - file could not be opened: ', File], 0) ,
	fail.

l_read_stream_to_list(Stream,[]) :-
	at_end_of_stream(Stream) ,
	! .

l_read_stream_to_list(Stream,[Line|Rest]) :-
	\+ at_end_of_stream(Stream),
	read_line_to_codes(Stream,X),
	atom_codes(Line, X),
	l_read_stream_to_list(Stream,Rest).


/* ========================================================================
OS predicates
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
l_current_os(unix) :-
	current_prolog_flag(unix, true) ,
	! .
l_current_os(win) :-
	current_prolog_flag(windows, true) .

% -----------------------------------------------------------------------

l_get_date_time(Year, Month, Day, Hour, Minute, Second, Microsecond) :-
	get_time(T),
	stamp_date_time(T, date(Year, Month, Day, Hour, Minute, S, _, _, _), 'local') ,
	Second is round(float_integer_part(S)) ,
	Microsecond is round(float_integer_part(1000 * float_fractional_part(S))) .

l_current_date(Date) :-
	l_get_date_time(Year, M, D, _Hour, _Minute, _Second, _Microsecond) ,
	pad0(M, Month) ,
	pad0(D, Day) ,
	atomic_list_concat([Year, Month, Day], '-', Date).

l_current_time(Time) :-
	l_get_date_time(_Year, _Month, _Day, H, M, S, _Microsecond) ,
	pad0(H, Hour) ,
	pad0(M, Minute) ,
	pad0(S, Second) ,
	atomic_list_concat([Hour, Minute, Second], ':', Time).

% -----------------------------------------------------------------------
% Extract last modification date and time for a file

l_file_date_time(File, Date, Time) :-
	time_file(File, TS),
	stamp_date_time(TS, date(Year, Mo, Da, Ho, Mi, Se, _, _, _), 'local') ,
	pad0(Mo, Month) ,
	pad0(Da, Day) ,
	atomic_list_concat([Year, Month, Day], '-', Date) ,
	pad0(Ho, Hour) ,
	pad0(Mi, Minute) ,
	Se0 is truncate(Se),
	pad0(Se0, Second) ,
	atomic_list_concat([Hour, Minute, Second], ':', Time) .

pad0(Number, Padded) :-
	atom_length(Number, 1) ,
	! ,
	atomic_concat('0', Number, Padded) .

pad0(Number, Number) :-
	atom_length(Number, 2) .


/* ========================================================================
Debug tools
Trace level:
  0 - Nothing traced
  1 - Errors traced
  2 - As 1, but some more
  3 - Warnings
  4 - A lot
  5 - All that could be useful

Also possible to restrict writes due to debug topics.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

l_set_trace_lvl(X) :-
	X > -1 ,
	X < 6 ,
	l_erase_all(l_trace_lvl) ,
	recorda(l_TRACE_LVL, l_TRACE_LVL(X)) .

l_trace_lvl(X) :-
	recorded(_, l_TRACE_LVL(X), _) ,
	! .

% Trace lvl default is 0
l_trace_lvl(0) .

l_write_trace(List, Lvl, Topic) :-
	debugging(Topic) ,
	!,
	l_write_trace(List, Lvl) .

l_write_trace(_List, _Lvl, _Topic) .

l_write_trace(ToWrite, Lvl) :-
	atom(ToWrite),
	! ,
	l_write_trace([ToWrite], Lvl) .

l_write_trace(List, Lvl) :-
	l_trace_lvl(CurrentLvl),
	CurrentLvl >= Lvl ,
	l_write_list(['** Trace (', Lvl, '): ']) ,
	write_list(user_output, List, ' | ', '') ,
	nl ,
	! .
l_write_trace(_,_) .

/* =======================================================================
XML and HTML predicates
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Load a DOM document from an URL or a file
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

l_load_dom_http(URL, DOM) :-
	catch(
	    http_load_html(URL, DOM),
	    Error,
	    (
		print_message(warning, Error),
		fail
	    )
	),
	! .

l_load_dom_file(File, DOM) :-
	catch(
	    load_html_file(File, DOM),
	    Error,
	    (
		print_message(warning, Error),
		fail
	    )
	),
	! .

http_load_html(URL, DOM) :-
	setup_call_cleanup(
	    http_open(URL, In,
		      [ timeout(60)
		      ]),
	    (   dtd(html, DTD),
		load_structure(stream(In),
			       DOM,
			       [ dtd(DTD),
				 dialect(xml),
				 shorttag(false),
				 max_errors(-1),
				 syntax_errors(quiet)
			       ])
	    ),
	    close(In)).


/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
print_dom must be generalized
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
l_print_dom([], _ ) :- ! .

l_print_dom([H|T], Indent) :-
	! ,
	write_indent('[', Indent) ,
	Outdent = Indent+1 ,
	l_print_dom(H, Outdent) ,
	l_print_dom(T, Outdent) ,
	write_indent(']', Indent) .

l_print_dom(element(A,_,C), Indent) :-
	! ,
	write_indent('element(', Indent),
	Outdent = Indent+1 ,
	write_indent(A, Outdent),
	l_print_dom(C, Outdent) ,
	write_indent(')', Indent).

l_print_dom(Text, Indent) :-
	write_indent(Text, Indent) .

l_urlencode(TkbLink1, TkbLink2) :-
	atom_codes(TkbLink1, CharList1) ,
	urlencode2(CharList1, CharList2) ,
	atom_codes(TkbLink2, CharList2).

urlencode2([], []) :- ! .

% Convert space to %20
urlencode2([32|Rest] , [37,50,48 | Rest2]) :-
	! ,
	urlencode2(Rest, Rest2).

urlencode2([Char|Rest] , [Char | Rest2]) :-
	urlencode2(Rest, Rest2).

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Get hostname from URL
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
l_get_hostname(URL, Hostname) :-
	atomic_list_concat([_Prot, '', Hostname | _Args] , '/', URL) .
%	atomic_list_concat([Hostname2 | _], ':', Hostname ).


/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Predicate to write HTML structures, as HTML, to a stream
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
% No stream, set to user_output
l_html_write(Content) :-
	l_html_write(Content, user_output) ,
	! .

l_html_write(Content, Stream) :-
	html_write2(Content, Stream) ,
	! .

% Empty list, do nothing
html_write2([], _Stream) :- ! .

% Handle elements in a list
html_write2([Content | Rest], Stream) :-
	! ,
	html_write2(Content, Stream) ,
	html_write2(Rest, Stream) .

% --- Special tags
% string-tag
html_write2(string(String), Stream) :-
	! ,
	write(Stream, String) .

% comment-tag
html_write2(comment(Comment), Stream) :-
	! ,
	l_write_list(Stream, [
			 nl ,
			 '<!-- ' ,
			 Comment ,
			 ' -->',
			 nl ]) .

/*

       <a class="info" href="#">Info</a><span class="help-text">Texten som ska visas i pop:uppen när musen hovrar över ikonen.</span>
	*/
html_write2(info(Text), Stream) :-
	html_write2(info(right, Text), Stream) .

html_write2(info(Side, Text), Stream) :-
	! ,
	(   Side = 'left' -> Pos = 'help-text-left' ; Pos = 'help-text-right' ),
	html_write2([
	    a([attribute(class, info), attribute(href, '#') ] ,
	      ['Info ' , span(attribute(class, Pos), Text) ])
	] ,
		    Stream ) .

html_write2(newline, Stream) :-
	nl(Stream),
	write(Stream, '<br>' ) ,
	nl(Stream) .


% A tag with no attributes specified, specify as []
html_write2(Struct, Stream) :-
	Struct =.. [Tag, Content] ,
	! ,
	Struct2 =.. [Tag, [], Content] ,
	html_write2(Struct2, Stream) .

% A tag
html_write2(Struct, Stream) :-
	Struct =.. [Tag, Attributes, Content] ,
	! ,
	html_write_starttag(Tag, Attributes, Stream),
	html_write2(Content, Stream) ,
	html_write_endtag(Tag, Stream).

html_write2(Content, Stream) :-
	atom(Content) ,
	! ,
	write(Stream, Content) .

html_write_starttag(Tag, Attributes, Stream) :-
	( html_nl_before_starttag(Tag) -> nl(Stream) ; true ) ,
	! ,
	write(Stream, '<') ,
	write(Stream, Tag),
	html_write_attributes(Attributes, Stream) ,
	write(Stream, '>') ,
	( html_nl_after_starttag(Tag) -> nl(Stream) ; true ) .

html_write_endtag(Tag, Stream) :-
	( html_nl_before_endtag(Tag) -> nl(Stream) ; true ) ,
	write(Stream, '</') ,
	write(Stream, Tag),
	write(Stream, '>') ,
	( html_nl_after_endtag(Tag) -> nl(Stream) ; true ) .

html_nl_before_starttag(Tag) :-
	member(Tag, [html, head, meta, link, title, body, h1, h2, h3, h4, h5, p, table, tr, ul, ol, li, release] ),
	! .

html_nl_after_starttag(Tag) :-
	member(Tag, [domains, domain] ),
	! .

html_nl_before_endtag(Tag) :-
	member(Tag, [table, ul, domain] ),
	! .

html_nl_after_endtag(Tag) :-
	member(Tag, [h1, h2, h3, h4, h5, table, title, body, p, meta, head, domain, serviceContract] ),
	! .

html_write_attributes([], _Stream) :- ! .

html_write_attributes(attribute(Key, Value), Stream) :-
	! ,
	html_write_attributes([attribute(Key, Value)], Stream) .

html_write_attributes([attribute(Key, Value)|Rest], Stream) :-
	write(Stream, ' ') ,
	write(Stream, Key), write(Stream, '='), write(Stream, '"'), write(Stream, Value) , write(Stream, '"') ,
	html_write_attributes(Rest, Stream) .



/* ========================================================================
Paths, files names represented as reversed list (rpath)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Convert between a path and an rpath
A path starting with a slash result in a rpath ending with item '/'.
A trailing slash will always be removed.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
l_path_to_rpath(Path, Rpath2) :-
	nonvar(Path),
	! ,
	atomic_list_concat(NameList, '/', Path),
	path_to_rpath2(NameList, NameList2),
	reverse(NameList2, Rpath) ,
	path_to_rpath3(Rpath, Rpath2) .

l_path_to_rpath(Path, Rpath) :-
	nonvar(Rpath),
	reverse(Rpath, Rpath2),
	path_to_rpath2(Rpath3, Rpath2),
	atomic_list_concat(Rpath3, '/', Path),
	l_check_path_length(Path) .


path_to_rpath2(['' | Rest], ['/' | Rest]) :-! .
path_to_rpath2(Rest, Rest) .

path_to_rpath3(['' | Rest], Rest) :- ! .
path_to_rpath3(Rest, Rest) .

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Find content of an folder refered by an rpath
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
l_ls(Rpath, ItemList4) :-
	l_path_to_rpath(Dir, Rpath),
	l_check_path_length(Dir),
	exists_directory(Dir),
	directory_files(Dir, ItemList) ,
	delete(ItemList, '.', ItemList2) ,
	delete(ItemList2, '..', ItemList3) ,
	sort(ItemList3, ItemList4) .

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Check path length and verify it will work in windows
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
l_check_path_length(Path) :-
	l_current_os(win),
	! ,
	atom_length(Path, Len),
	Len < 220 .

l_check_path_length(_) .



/* ===========================================================================
Relaterade anteckningar

Kommando för att kovertera från docx till text: libreoffice --invisible
--convert-to txt:Text filnamn.docx

============================================================================== */

lNotequal(X, X) :-
    !,
    fail.

lNotequal(_, _) .







