:- module(restapi, [
    server/0,
    server/1
    ]).

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_error)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/http_json)).

%:- use_module(library(http/http_header)). % Needed ???
:- use_module(taklib).

% Declare a handler, binding an HTTP path to a predicate.
% The notation root(hello_world) uses an alias-mechanism similar to
% absolute_file_name/3 and allows for moving parts of the server locations
% easily. See http_absolute_location/3.
:- http_handler(root(.), say_hi, []).

% And, just for clarity, define a second handler
% this one can by reached at http://127.0.0.1:8000/taco
:- http_handler(root('api/classic/connectionPoints'), apiClassicConnectionPoints, []).
:- http_handler(root('api/classic/logicalAddresss'), apiClassicLogicalAddresss, []).
:- http_handler(root('api/classic/serviceContracts'), apiClassicServiceContracts, []).
:- http_handler(root('api/classic/serviceConsumers'), apiClassicServiceConsumers, []).
:- http_handler(root('api/classic/serviceProducers'), apiClassicServiceProducers, []).
:- http_handler(root('api/classic/cooperations'), apiClassicCooperations, []).
:- http_handler(root('api/classic/serviceProductions'), apiServiceProductions, []).

:- http_handler(root('api/plview/connectionPoints'), apiPlviewConnectionPoints, []).
:- http_handler(root('api/plview/serviceConsumers'), apiPlviewServiceConsumers, []).
:- http_handler(root('api/plview/serviceProducers'), apiPlviewServiceProducers, []).
:- http_handler(root('api/plview/logicalAddresss'), apiPlviewLogicalAddresss, []).
:- http_handler(root('api/plview/serviceContracts'), apiPlviewServiceContracts, []).
:- http_handler(root('api/plview/dates'), apiPlviewDates, []).
:- http_handler(root('api/plview/plattformChains'), apiPlviewPlattformChains, []).
:- http_handler(root('api/plview/performFiltering'), apiPlviewPerformFiltering, []).

% The predicate server(?Port) starts the server. It simply creates a
% number of Prolog threads and then returns to the toplevel, so you can
% (re-)load code, debug, etc.
server :- server(5000) .
server(Port) :-
        http_server(http_dispatch, [port(Port)]).

/* The implementation of /hello_world. The single argument provides the request
details, which we ignore for now. Our task is to write a CGI-Document:
a number of name: value -pair lines, followed by two newlines, followed
by the document content, The only obligatory header line is the
Content-type: <mime-type> header.
Printing can be done using any Prolog printing predicate, but the
format-family is the most useful. See format/2.   */

say_hi(_Request) :-
        format('Content-type: text/plain~n~n'),
        format('Hello all of the World!~n').

/*
    todo: Remove the date parameters from the base get API calls and just use date for the filter call
    These base calls should return all items with their id and description
*/

apiClassicConnectionPoints(Request) :-
        http_parameters(Request, [
                                    date(_Date, [optional(true), default('Today')])
                                 ]) ,
        allClassicConnectionPoints(CpList),
        format('Access-Control-Allow-Origin: *'), nl,
        reply_json(CpList) .

apiClassicLogicalAddresss(Request) :-
        http_parameters(Request,
            [ connectionPointId(CpId, [optional(false)] )
            ]) ,
        classicLogicalAddress(CpId, LaList),
        format('Access-Control-Allow-Origin: *'), nl,
        reply_json(LaList) .

apiClassicServiceContracts(Request) :-
        http_parameters(Request,
            [ connectionPointId(CpId, [optional(false)] )
            ]) ,
        classicServiceContracts(CpId, ScList),
        format('Access-Control-Allow-Origin: *'), nl,
        reply_json(ScList) .

apiClassicServiceConsumers(Request) :-
        http_parameters(Request,
            [ connectionPointId(CpId, [optional(false)] )
            ]) ,
        classicServiceConsumers(CpId, ScList),
        format('Access-Control-Allow-Origin: *'), nl,
        reply_json(ScList) .

apiClassicServiceProducers(Request) :-
        http_parameters(Request,
            [ connectionPointId(CpId, [optional(false)] )
            ]) ,
        classicServiceProducers(CpId, ScList),
        format('Access-Control-Allow-Origin: *'), nl,
        reply_json(ScList) .

apiClassicCooperations(Request) :-
        http_parameters(Request,
            [ connectionPointId(CpId, [optional(false)] )
            ]) ,
        classicCooperations(CpId, ScList),
        format('Access-Control-Allow-Origin: *'), nl,
        reply_json(ScList) .

apiServiceProductions(Request) :-
        http_parameters(Request,
            [ connectionPointId(CpId, [optional(false)] )
            ]) ,
        classicServiceProductions(CpId, ScList),
        format('Access-Control-Allow-Origin: *'), nl,
        reply_json(ScList) .

% -----------------------------------------------------------------------------------------

apiPlviewConnectionPoints(Request) :-
        http_parameters(Request, [
                                    date(Date, [optional(false), default('Today')])
                                 ]) ,
        ensureDate(Date, ActualDate) ,
        allPlviewConnectionPoints(ActualDate, CpList),
        format('Access-Control-Allow-Origin: *'), nl,
        reply_json(CpList) .

apiPlviewServiceConsumers(Request) :-
        http_parameters(Request, [
                                    date(Date, [optional(false), default('Today')])
                                 ]) ,
        ensureDate(Date, ActualDate) ,
        plviewServiceConsumers(ActualDate, CpList),
        format('Access-Control-Allow-Origin: *'), nl,
        reply_json(CpList) .

apiPlviewServiceProducers(Request) :-
        http_parameters(Request, [
                                    date(Date, [optional(false), default('Today')])
                                 ]) ,
        ensureDate(Date, ActualDate) ,
        plviewServiceProducers(ActualDate, CpList),
        format('Access-Control-Allow-Origin: *'), nl,
        reply_json(CpList) .

apiPlviewLogicalAddresss(Request) :-
        http_parameters(Request, [
                                    date(Date, [optional(false), default('Today')]),
                                    connectionPointId(_CpId, [optional(true)])
                                 ]) ,
        ensureDate(Date, ActualDate) ,
        plviewLogicalAddresss(ActualDate, CpList),
        format('Access-Control-Allow-Origin: *'), nl,
        reply_json(CpList) .

apiPlviewServiceContracts(Request) :-
        http_parameters(Request, [
                                    date(Date, [optional(false), default('Today')])
                                 ]) ,
        ensureDate(Date, ActualDate) ,
        plviewServiceContracts(ActualDate, CpList),
        format('Access-Control-Allow-Origin: *'), nl,
        reply_json(CpList) .

apiPlviewDates(Request) :-
        http_parameters(Request, [
                                 ]) ,
        plviewDates(List),
        format('Access-Control-Allow-Origin: *'), nl,
        reply_json(List) .

apiPlviewPlattformChains(Request) :-
        http_parameters(Request, [
                                    date(Date, [optional(false), default('Today')])
                                 ]) ,
        ensureDate(Date, ActualDate) ,
        plviewPlattformChains(ActualDate, List),
        format('Access-Control-Allow-Origin: *'), nl,
        reply_json(List) .

apiPlviewPerformFiltering(Request) :-
        http_parameters(Request, [
                                    date(              Date,       [optional(false), default('Today')]),
                                    %connectionPointId( TpIds,      [optional(true)]),
                                    plattformChainId(  TpIds,      [optional(true)]),
                                    serviceConsumerId( ConsumerId, [optional(true)]),
                                    serviceProducerId( ProducerId, [optional(true)]),
                                    serviceContractId( ContractId, [optional(true)]),
                                    logicalAddressId(  LaId,       [optional(true)])
                                 ]) ,
        ensureDate(Date, ActualDate) ,
        decodeTpIds(TpIds, TpList) ,
        plviewPerformFiltering(ActualDate, TpList, ConsumerId, ProducerId, ContractId, LaId, List),
        format('Access-Control-Allow-Origin: *'), nl,
        reply_json(List) .

/***********************************************************************************
 * The calls mirrored from the PHP API
 * The hypotesis is to not use any parameters for the basic fetch calls. Only allow parameters
 * in the filter call.
 * *********************************************************************************/
% Connection points in the format required of the classic hippo view
allClassicConnectionPoints(List) :-
	setof(json([id= Id, platform= Platform, environment= Environment, snapshotTime= SnapshotTime]) ,
	      PlatformEnvironment^classicConnectionPoint(Id, PlatformEnvironment, Platform, Environment, SnapshotTime) ,
	      List) .


% Logical addresses -------------------------------------
classicLogicalAddress(CpId, List) :-
    classicConnectionPoint(CpId, Tp, _Platform, _Environment, Date) ,
    setof(json([id= LA, logicalAddress= LA, description= Desc]) ,
	      classicLogicalAddress2(Tp, Date, LA, Desc) ,
	      List) .

classicLogicalAddress2(Tp, Date, LA, Desc) :-
	logicalAddress(LA, Desc) ,
	serviceProduction(LA, _Namespace, _ServiceComponentHsaId, Tp, _Url, _RivTaProfile, Date) .

% Service contract --------------------------------------
classicServiceContracts(CpId, List) :-
    classicConnectionPoint(CpId, Tp, _Platform, _Environment, Date) ,
	setof(json([id= Namespace, name= Name, namespace= Namespace, major= Major, minor= Minor]) ,
	      classicServiceContracts2(Tp, Date, Namespace, Name, Major, Minor) ,
	      List) .

classicServiceContracts2(Tp, Date, Namespace, Contract, Major, Minor) :-
    serviceContract(Namespace, _Domain, Contract, Major, Minor) ,
    serviceProduction(_LA, Namespace, _ServiceComponentHsaId, Tp, _Url, _RivTaProfile, Date) .


% Service consumers
classicServiceConsumers(CpId, List) :-
    classicConnectionPoint(CpId, Tp, _Platform, _Environment, Date) ,
	setof(json([id= HsaId, description= Desc, hsaId= HsaId]) ,
	      classicServiceConsumers2(Tp, Date, HsaId, Desc) ,
	      List) .

classicServiceConsumers2(Tp, Date, HsaId, Desc) :-
    serviceConsumer(HsaId, Desc) ,
    cooperation(_LogicalAddress, _Namespace, HsaId, Tp, Date) .

% Service producers
classicServiceProducers(CpId, List) :-
    classicConnectionPoint(CpId, Tp, _Platform, _Environment, Date) ,
	setof(json([id= HsaId, description= Desc, hsaId= HsaId]) ,
	      classicServiceProducers2(Tp, Date, HsaId, Desc) ,
	      List) .

classicServiceProducers2(Tp, Date, HsaId, Desc) :-
    serviceProducer(HsaId, Desc) ,
    serviceProduction(_LogicalAddress, _Namespace, HsaId, Tp, _Url, _RivTaProfile, Date) .


% cooperations
classicCooperations(CpId, List) :-
    classicConnectionPoint(CpId, Tp, _Platform, _Environment, Date) ,
	setof(json([id= Id,
	            serviceConsumer= json([id= HsaId, hsaId= HsaId, description= 'ConsumerDescription']),
	            logicalAddress= json([id= LA, logicalAddress= LA, description= 'LaDescription']) ,
	            serviceContract= json([id= NS, namespace= NS, name= 'ContractName', major= 1, minor=0])
	             ]),
	      classicCooperations2(Tp, Date, Id, LA, NS, HsaId) ,
	      List) .

classicCooperations2(Tp, Date, Id, LA, NS, HsaId) :-
    cooperation(LA, NS, HsaId, Tp, Date) ,
    atomic_list_concat([LA, NS, HsaId], '|', Id) .

% serviceProductions
classicServiceProductions(CpId, List) :-
    classicConnectionPoint(CpId, Tp, _Platform, _Environment, Date) ,
	setof(json([id= Id,
	            physicalAddress= Url,
	            rivtaProfile= RivTaProfile,
	            serviceProducer= json([id= HsaId, hsaId= HsaId, description= 'ConsumerDescription']),
	            logicalAddress= json([id= LA, logicalAddress= LA, description= 'LaDescription']) ,
	            serviceContract= json([id= NS, namespace= NS, name= 'ContractName', major= 1, minor=0])
	             ]),
	      classicServiceProductions2(Tp, Date, Id, LA, NS, HsaId, Url, RivTaProfile) ,
	      List) .

classicServiceProductions2(Tp, Date, Id, LA, NS, HsaId, Url, RivTaProfile) :-
    serviceProduction(LA, NS, HsaId, Tp, Url, RivTaProfile, Date) ,
    atomic_list_concat([LA, NS, HsaId], '|', Id) .

% --------------------------------------------------------------------------------------------

allPlviewConnectionPoints(Date, List) :-
	setof(json([id= Id, platform= Platform, environment= Environment, snapshotTime= SnapshotTime]) ,
	      plviewConnectionPoint(Date, Id, Platform, Environment, SnapshotTime) ,
	      List) .

plviewServiceConsumers(Date, List) :-
	setof(json([id= HsaId, description= Desc, hsaId= HsaId]) ,
   	      Tp^classicServiceConsumers2(Tp, Date, HsaId, Desc) ,
   	      List) .

plviewServiceProducers(Date, List) :-
	setof(json([id= HsaId, description= Desc, hsaId= HsaId]) ,
   	      Tp^classicServiceProducers2(Tp, Date, HsaId, Desc) ,
   	      List) .

plviewLogicalAddresss(Date, List) :-
    setof(json([id= LA, logicalAddress= LA, description= Desc]) ,
	      Tp^classicLogicalAddress2(Tp, Date, LA, Desc) ,
	      List) .

plviewServiceContracts(Date, List) :-
    setof(json([id= Namespace, name= Name, namespace= Namespace, major= Major, minor= Minor]) ,
          Tp^classicServiceContracts2(Tp, Date, Namespace, Name, Major, Minor) ,
          List) .

/*
  {
    "id": 0,
    "dates": [
      "2017-08-31"
    ]
  }
*/
plviewDates(json([id=0, dates=DateList])) :- takDates(DateList) .
%plviewDates(json(dates= DateList)) :- takDates(DateList) .



/*
  {
    "id": "6-2"
  },
  {
    "id": "2"
  },
*/
plviewPlattformChains(Date, List) :-
	setof(json([id= PlattformChain]) ,
   	      plviewPlattformChains2(Date, PlattformChain) ,
   	      List) .

plviewPlattformChains2(Date, Tp) :- tpIntegration(_ConsumerHsaId, _Namespace, [Tp], _LogicalAddress, _ProducerHsaId, Date) .

plviewPlattformChains2(Date, TpChain) :-
    tpIntegration(_ConsumerHsaId, _Namespace, [TpLeft, Tpright], _LogicalAddress, _ProducerHsaId, Date) ,
    atomic_list_concat([TpLeft, Tpright], '>', TpChain) .

/*
json( serviceConsumers= ConsumerJsonList,
                serviceProducers= ProducerJsonList,
                serviceContracts= NSJsonList,
                logicalAddresses= LaJsonList,
                consumerConnectionPoints= ,
                producerConnectionPoints= ,
                plattformChains=

                json([
                    serviceConsumers=[json([id='SE2321000016-8K5F'])],
                    serviceContracts=[
                                      json([id='urn:riv:infrastructure:eservicesupply:forminteraction:CreateFormResponder:2']),
                                      json([id='urn:riv:infrastructure:supportservices:forminteraction:SaveFormResponder:1'])
                                      ]
                       ])
*/

plviewPerformFiltering(Date, TpList, ConsumerId, ProducerId, ContractId, LaId,
    json([
        serviceConsumers= ConsumerHsaIdListJson,
        serviceContracts= NamsepaceListJson,
        logicalAddresses= LogicalAddressListJson,
        serviceProducers= ProducerHsaIdListJson,
        plattformChains= TpListListJson
        ])
    ) :-
    tpIntegrationGrouped(ConsumerId, ContractId, TpList, LaId, ProducerId, Date,
                         groupLists(ConsumerHsaIdList,
                                    NamsepaceList,
                                    TpListList,
                                    LogicalAddressList,
                                    ProducerHsaIdList
                                    )
                       ) ,
    mkFilterJsonList(ConsumerHsaIdList, ConsumerHsaIdListJson) ,
    mkFilterJsonList(NamsepaceList, NamsepaceListJson),
    mkFilterJsonListTpList(TpListList, TpListListJson),
    mkFilterJsonList(LogicalAddressList, LogicalAddressListJson) ,
    mkFilterJsonList(ProducerHsaIdList, ProducerHsaIdListJson) .


mkFilterJsonList([], []) :- ! .
mkFilterJsonList([Head|Tail], [json([id= Head]) | JsonTail]) :-
    mkFilterJsonList(Tail, JsonTail) .

mkFilterJsonListTpList([], []) :- ! .
mkFilterJsonListTpList([Head|Tail], [json([id= TpId]) | JsonTail]) :-
    decodeTpIds(TpId, Head),
    mkFilterJsonListTpList(Tail, JsonTail) .


% Common predicates -------------------------
classicConnectionPoint(TpDate, PlatformEnvironment, Platform, Environment, SnapshotTime) :-
	connectionPoint(PlatformEnvironment, SnapshotTime) ,
	atomic_list_concat([Platform,Environment], '-', PlatformEnvironment) ,
	atomic_list_concat([SnapshotTime,PlatformEnvironment], '_', TpDate) .

/*
  {
    "id": 2,
    "platform": "NTJP",
    "environment": "QA",
    "snapshotTime": "2017-08-31 01:05:05"
  },
*/
plviewConnectionPoint(Date, Tp, Platform, Environment, SnapshotTime) :-
	connectionPoint(Tp, SnapshotTime) ,
	once(serviceProduction(_LA, _NS, _HsaId, Tp, _Url, _RivTaProfile, Date)) ,
	atomic_list_concat([Platform,Environment], '-', Tp) .

ensureDate('Today', Date) :-
    ! ,
    latestUpdateDate(Date) .
ensureDate(Date, Date) .

decodeTpIds(TpIds, TpLeftTpRight) :-
    nonvar(TpIds) ,
    var(TpLeftTpRight) ,
    ! ,
    atomic_list_concat(TpLeftTpRight, '>', TpIds) .
decodeTpIds(TpIds, TpLeftTpRight) :-
    var(TpIds) ,
    nonvar(TpLeftTpRight) ,
    length(TpLeftTpRight, 2) ,
    ! ,
    atomic_list_concat(TpLeftTpRight, '>', TpIds) .
decodeTpIds(TpId, [TpId]) .


% Platform chains

% performFiltering

/*
:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_error)).
:- use_module(library(http/http_json)).


%:- http_handler(public(think), think, []).
:- http_handler(/, think, []).

server(Port) :-
        http_server(http_dispatch, [port(Port)]).

think(Request) :-
    write(hej) , nl .



http_read_json_dict(Request, Query),
    solve_and_reset(Query, Solution),
    reply_json_dict(Solution).

*/