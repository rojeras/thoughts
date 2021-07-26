:- use_module(leolib).
:- use_module(taklib).


/*********************************************************
 * Evalutation predicates
 * *******************************************************/

/*********************************************************
 * Free text search
 ********************************************************/
freetext(Text) :-
    \+ is_list(Text) ,
    ! ,
    freetext([Text]) .

freetext(SourceList) :-
    tpIntegration(ConsumerHsaId, ConsumerDescription,
              Namespace, Domain, Contract, _Major, _Minor,
              TpList,
              LogicalAddress, LogicalAddressDescription,
              ProducerHsaId, ProducerDescription,
              _Date) ,
    atomic_list_concat(TpList, ' ', TpListCombined) ,
    multipleSubstringsInList(SourceList, [ConsumerHsaId,
                        ConsumerDescription,
                        Namespace,
                        Domain,
                        Contract,
                        TpListCombined,
                        LogicalAddress,
                        LogicalAddressDescription,
                        ProducerHsaId,
                        ProducerDescription]) ,
    l_write_list([nl,
                  '-----------------------------------------------------------------',
                  nl,
                  ConsumerHsaId, ' ',
                  ConsumerDescription, ' ',
                  Namespace, ' ',
                  Domain, ' ',
                  Contract, ' ',
                  TpListCombined, ' ',
                  LogicalAddress, ' ',
                  LogicalAddressDescription, ' ',
                  ProducerHsaId, ' ',
                  ProducerDescription, ' ',
                  nl]) ,
    fail.
freetext(_Text) .

multipleSubstringsInList([], _TargetList) :- ! .
multipleSubstringsInList([Text | Rest], TargetList) :-
    substringInList(Text, TargetList) ,
    ! ,
    multipleSubstringsInList(Rest, TargetList) .

multipleSubstringsInList(_SourceList, _TargetList) :- fail .

substringInList(_Text, []) :-
    ! ,
    fail .

substringInList(Text, [First | _Rest]) :-
    sub_atom(First, _, _, _, Text) ,
    ! .
substringInList(Text, [_First | Rest]) :-
    substringInList(Text, Rest) .

/* ---------------------------------------------------------------------
 *  Show contracts that does not exist in SLL-Prod
 *  --------------------------------------------------------------------
 */
contractsNotInTp(TpName, Domain, Contract, Major, Minor) :-
    serviceContract(Namespace, Domain, Contract, Major, Minor) ,
    \+ tpIntegration(_XConsumerHsaId, _XConsumerDescription,
                         Namespace, _XDomain, _XContract, _XMajor, _XMinor,
                         [TpName],
                         _XLogicalAddress, _XLogicalAddressDescription,
                         _XProducerHsaId, _XProducerDescription,
                         _XDate) .

showContractsNotInTp(TpName) :- showContractsNotInTp(TpName, terminal) .

showContractsNotInTp(TpName, File) :-
    contractsNotInTp(TpName, Domain, Contract, Major, Minor) ,
    l_write_file(File,
                  [Domain, ';',
                   Contract, ';',
                   Major, ';',
                   Minor, ' ',
                   nl]) ,
    fail.
showContractsNotInTp(_File, _TpName) .

/**************************************************************************************
 * Evalute case in Logical address
 * */
show_lowercase_la :-
    logicalAddress(LA,Desc),
    upcase_atom(LA, LaUp),
    \+ LA = LaUp ,
    once(serviceProduction(LA, _Namespace, _ServiceComponentHsaId, Tp, _Url, _RivTaProfile, _Date)) ,
    write(Tp), write(';'), write(LA), write(';'), write(Desc) , nl,
    fail .

%!  show_la_case_collide()
%
show_la_case_collide :-
    logicalAddress(LA,Desc),
    upcase_atom(LA, LaUp),
    \+ LA = LaUp ,
    logicalAddress(LaUp, DescUp),
    once(serviceProduction(LaUp, _Namespace, _ServiceComponentHsaId, Tp, _Url, _RivTaProfile, _Date)) ,
    write(Tp), write(';'), write(LA), write(';'), write(Desc) , write(';'),
    write(LaUp), write(';'), write(DescUp), nl,
    fail.

/* ---------------------------------------------------------------------
 *
 *
 *  Show contracts that only exists in SLL-Prod
 *  --------------------------------------------------------------------
 */
/*
showSllContract :-
	serviceProduction(_A, NS, _C, 'SLL-PROD', _E, _F, '2017-08-07'),
	notInOther(NS) ,
	write(NS), nl ,
	fail .
showSllContract .

notInOther(NS) :-
	serviceProduction(_H, NS, _I, Tak, _J, _K, '2017-08-07') ,
	member(Tak, ['NTJP-PROD', 'NTJP-QA', 'NTJP-TEST']) ,
	! ,
	fail .
notInOther(_NS) .
*/

/*
% -----------------------------------------------------------------------
% Routing without any call autionrization
% -----------------------------------------------------------------------
routingNoCallAuth :-
    routingNoCallAuth2(user_output ).

routingNoCallAuth(File) :-
    open(File, write, Stream, []) ,
    routingNoCallAuth2(Stream ).

routingNoCallAuth2(Stream) :-
    l_write_list(Stream, ['Tjänsteplattform', ' ; ', 'ProducerHsaId', ' ; ', 'ProducerDescription', ' ; ', 'Namespace', ' - ', ' ; ', 'LogicalAddress', ' ; ', 'LogicakAddressDescription',  nl] ) ,
    serviceProduction( _, TpName, ProducerHsaId, Namespace, LogicalAddress, _, _) ,
    \+ cooperation( _, TpName, _, Namespace, LogicalAddress) ,
    serviceProducer( ProducerHsaId, ProducerDescription, TpName) ,
    logicalAddress( LogicalAddress, LaDescription ) ,
    l_write_list(Stream, [TpName, ' ; ', ProducerHsaId, ' ; ', ProducerDescription, ' ; ', Namespace, ' - ', ' ; ', LogicalAddress, ' ; ', LaDescription,  nl] ) ,
    fail.
routingNoCallAuth2(Stream) :- close(Stream) .

% -----------------------------------------------------------------------
% Call authonrization without routing
% -----------------------------------------------------------------------
callAuthNoRouting :- callAuthNoRouting2(user_output ).

callAuthNoRouting(File) :-
    open(File, write, Stream, []) ,
    callAuthNoRouting2(Stream ).

callAuthNoRouting2(Stream) :-
    l_write_list(Stream, ['Tjänsteplattform', ' ; ', 'ConsumerHsaId', ' ; ', 'ConsumerDescription', ' ; ', 'Namespace', ' - ', ' ; ', 'LogicalAddress', ' ; ', 'LogicakAddressDescription',  nl] ) ,
    cooperation( _, TpName, ConsumerHsaId, Namespace, LogicalAddress) ,
    \+ serviceProduction( _, TpName, _, Namespace, LogicalAddress, _, _) ,
    serviceProducer( ConsumerHsaId, ConsumerDescription, TpName) ,
    logicalAddress( LogicalAddress, LaDescription ) ,
    l_write_list(Stream, [TpName, ' ; ', ConsumerHsaId, ' ; ', ConsumerDescription, ' ; ', Namespace, ' - ', ' ; ', LogicalAddress, ' ; ', LaDescription,  nl] ) ,
    fail.
callAuthNoRouting2(Stream) :- close(Stream) .


% -----------------------------------------------------------------------
% Find mismatches between TPs
% -----------------------------------------------------------------------
mismatchFirstTp :- mismatchFirstTp2(user_output) .

mismatchFirstTp(File) :-
    open(File, write, Stream, []) ,
    mismatchFirstTp2(Stream) .

mismatchFirstTp2(Stream) :-
    l_write_list(Stream, ['Unknown Consumer ; Namespace ; TpLeft --> TpRight ; LogicalAddress ; LogicalAddressDescription ; Producer ; ProducerDescription', nl] ),
    tpIntegration(ConsumerRight, _, Namespace, TpRight, LogicalAddress, LogicalAddressDescription, Producer, ProducerDescription) ,
    metaplattform(ConsumerRight, TpLeft),
    notequal(TpLeft, TpRight) ,
    \+ tpIntegrationMulti(_, Namespace, TpLeft, TpRight, LogicalAddress, Producer) ,
    l_write_list(Stream, [ ' ; ', Namespace, ' ; ', TpLeft, ' --> ', TpRight, ' ; ', LogicalAddress, ' ; ', LogicalAddressDescription, ' ; ', Producer, ' ; ', ProducerDescription, nl] ),
    fail .
mismatchFirstTp2(Stream) :- close(Stream).

% -----------------------------------------------------------------------

mismatchSecondTp :- mismatchSecondTp2(user_output) .

mismatchSecondTp(File) :-
    open(File, write, Stream, []) ,
    mismatchSecondTp2(Stream) .

mismatchSecondTp2(Stream) :-
    l_write_list(Stream, ['Consumer ; ConsumerDescription ; Namespace ; TpLeft --> TpRight ; LogicalAddress ; LogicalAddressDescription ; Unknown Producer', nl] ),
    tpIntegration(Consumer, ConsumerDescription, Namespace, TpLeft, LogicalAddress, LogicalAddressDescription, ProducerLeft, _) ,
    metaplattform(ProducerLeft, TpRight),
    notequal(TpLeft, TpRight) ,
    \+ tpIntegrationMulti(Consumer, Namespace, TpLeft, TpRight, LogicalAddress, _) ,
    l_write_list(Stream, [Consumer, ' ; ', ConsumerDescription, ' ; ', Namespace, ' ; ', TpLeft, ' --> ', TpRight, ' ; ', LogicalAddress, ' ; ', LogicalAddressDescription, nl] ),
    fail .
mismatchSecondTp2(Stream) :- close(Stream).



*/
