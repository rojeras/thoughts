/** taklib Manage and access TAK data

This module make it possible to load and manage TAK data.

@author LEO
@license none
*/
:- module(taklib, [
              tpIntegration/6,
              tpIntegrationGrouped/7,
              tpIntegration/13,
              exportDb/1,
              importDb/1,
	          removeTak/0,
              taklibInit/0,
	          readTakApi/0,
              readTakFiles/0,
              connectionPoint/2,
              logicalAddress/2,
              serviceConsumer/2,
              serviceProducer/2,
              serviceComponent/2,
              serviceContract/5,
              serviceContract/8,
              cooperation/5,
              serviceProduction/7,
              takDates/1,
%              updateDates/1,
%              updateDates/2,
              latestUpdateDate/1
%              latestUpdateDate/2,
%              currentTakDate/2,
%	          extractInfoFromNamespace/5
	      ] ).

:- dynamic(dbConnectionPoint/2).
:- dynamic(dbBaseItem/4).
:- dynamic(dbServiceComponent/2).
:- dynamic(dbServiceContract/4).
:- dynamic(dbCooperation/7).
:- dynamic(dbServiceProduction/9).

:- use_module(library(http/http_open)).
:- use_module(library(http/json)).
:- use_module(leolib).

taklibInit :-
    set_prolog_stack(global, limit(2*10**9)).

% =========================================================
% Meta information about TPs
%

%! metaTpPrio(+Name:atom, +Id:int) is det.
%
%  Table of TAKs
metaTpPrio('NTJP-PROD', 1) .
metaTpPrio('SLL-PROD' , 2) .
metaTpPrio('NTJP-QA',   3) .
metaTpPrio('SLL-QA',    4) .
metaTpPrio('NTJP-TEST', 5) .

%!  metaplattform(+Hsa_Id, -Tak_Id) is det
%!  metaplattform(-Hsa_Id, ?Tak_Id) is nondet
%
%   Maps a HSA_Id to a certain TP TAK
metaplattform('HSASERVICES-106J','NTJP-PROD')  .
metaplattform('HSASERVICES-10HR', 'NTJP-PROD')  .
metaplattform('T_SERVICES_SE165565594230-1023', 'NTJP-QA')  .
metaplattform('T_SERVICES_SE165565594230-102X', 'NTJP-QA')  .
metaplattform('T_SERVICES_SE165565594230-109C', 'NTJP-TEST') .
metaplattform('T_SERVICES_SE165565594230-1098', 'NTJP-TEST') .
metaplattform('SE2321000016-7P37', 'SLL-PROD') .
metaplattform('SE2321000016-7P35', 'SLL-PROD') .
metaplattform('SE2321000016-8KWT', 'SLL-PROD') .
metaplattform('SE2321000016-A1WQ', 'SLL-QA') .
metaplattform('SE2321000016-A2G4', 'SLL-QA') .
metaplattform('SE2321000016-A22K', 'SLL-QA') .

%!  map_logicaladdress(+Wronlgy_Spelled, -Rightly_Spelled) is det
%
%   The TAK-api sometimes returned a logical address with lowercase
%   character. These will be mapped.

map_logicaladdress('SE2321000222-MedHc', 'SE2321000222-MEDHC') :- !  .
map_logicaladdress('NMTIntygIP40', 'NMTINTYGIP40') :- ! .
map_logicaladdress(LA, LA) .


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Access predicates. Used to retreive information about integrations in
% one och multiple TAKs.

%! tpIntegration() is nondet
%
% Show complete integration in a TP

tpIntegration(ConsumerHsaId, Namespace, [TpName], LogicalAddress, ProducerHsaId, Date) :-
    cooperation(LogicalAddress, Namespace, ConsumerHsaId, TpName, Date) ,
    serviceProduction(LogicalAddress, Namespace, ProducerHsaId, TpName, _Url, _RivTaProfile, Date) .

tpIntegration(ConsumerHsaId, Namespace, [TpLeft, TpRight], LogicalAddress, ProducerHsaId, Date) :-
    metaplattform(LeftProducerHsaId, TpRight),
    metaplattform(RightConsumerHsaId, TpLeft),
    \+ TpLeft = TpRight ,
    tpIntegration(ConsumerHsaId, Namespace, [TpLeft], LogicalAddress, LeftProducerHsaId, Date),
    tpIntegration(RightConsumerHsaId, Namespace, [TpRight], LogicalAddress, ProducerHsaId, Date) .

tpIntegration(ConsumerHsaId, ConsumerDescription,
              Namespace, Domain, Contract, Major, Minor,
              TpList,
              LogicalAddress, LogicalAddressDescription,
              ProducerHsaId, ProducerDescription,
              Date) :-
    tpIntegration(ConsumerHsaId, Namespace,  TpList, LogicalAddress, ProducerHsaId, Date) ,
    serviceConsumer(ConsumerHsaId, ConsumerDescription) ,
    serviceContract(Namespace, Domain, Contract, Major, Minor) ,
    logicalAddress(LogicalAddress, LogicalAddressDescription) ,
    serviceProducer(ProducerHsaId, ProducerDescription) .

% -------------------------------------------------------------------------------------------
tpIntegrationGrouped(ConsumerHsaId, Namespace, TpList, LogicalAddress, ProducerHsaId, Date, GroupLists) :-
    findall(integration(ConsumerHsaId, Namespace, TpList, LogicalAddress, ProducerHsaId),
          tpIntegration(ConsumerHsaId, Namespace, TpList, LogicalAddress, ProducerHsaId, Date) ,
          ListOfIntegrations ) ,
    tpIntegrationGrouped2(  ListOfIntegrations,
                            GroupLists
                         ) .

tpIntegrationGrouped2(  ListOfIntegrations,
                        groupLists(ConsumerHsaIdListSorted,
                                   NamsepaceListSorted,
                                   TpListListSorted,
                                   LogicalAddressListSorted,
                                   ProducerHsaIdListSorted)
                        ) :-
    tpIntegrationGrouped3(ListOfIntegrations,
                          groupLists(ConsumerHsaIdList,
                                     NamsepaceList,
                                     TpListList,
                                     LogicalAddressList,
                                     ProducerHsaIdList)
                           ) ,
    sort(ConsumerHsaIdList,ConsumerHsaIdListSorted) ,
    sort(NamsepaceList,NamsepaceListSorted) ,
    sort(TpListList,TpListListSorted) ,
    sort(LogicalAddressList,LogicalAddressListSorted) ,
    sort(ProducerHsaIdList, ProducerHsaIdListSorted) .



tpIntegrationGrouped3([], groupLists([], [], [], [], [])) :- ! .

tpIntegrationGrouped3( [integration(ConsumerHsaId, Namespace, TpList, LogicalAddress, ProducerHsaId) | ItIntegrationRest],
                       groupLists([ConsumerHsaId | ConsumerHsaIdRest],
                                  [Namespace | NamsepaceRest],
                                  [TpList | TpListRest],
                                  [LogicalAddress | LogicalAddressRest],
                                  [ProducerHsaId | ProducerHsaIdRest])
                       ) :-
    tpIntegrationGrouped3(ItIntegrationRest,
                       groupLists(ConsumerHsaIdRest,
                                  NamsepaceRest,
                                  TpListRest,
                                  LogicalAddressRest,
                                  ProducerHsaIdRest)
                         ) .

% *************************************************************************************************************************
% Load the TAKs from the TAK API,


takApiUrl(cooperations,
          'http://api.ntjp.se/coop/api/v1/cooperations?include=connectionPoint%2ClogicalAddress%2CserviceContract%2CserviceConsumer') :- ! .

takApiUrl(serviceProductions,
          'http://api.ntjp.se/coop/api/v1/serviceProductions?include=connectionPoint%2ClogicalAddress%2CserviceContract%2CserviceProducer%2CphysicalAddress') :- ! .

takApiUrl(Type, Url) :-
    atomic_list_concat(['http://api.ntjp.se/coop/api/v1', Type], '/', Url) .


readTakApi :-
%    removeTak,
    readTakApi(cooperations) ,
    readTakApi(serviceProductions) .

readTakApi(Type) :-
    l_write_list(['Loading ', Type, ' ...', nl]) ,
    takApiUrl(Type, Url),
    http_open(Url, Stream, [encoding(iso_latin_1)]) ,
    json_read(Stream, Json) ,
    storeTakList(Type, Json).


/*************************************************************************
 Read TAK data from files

 Instead of the API we pick up the data from the files containing the
 historical API-informaion.
 The connectionPoint is stored separatly from the cooperations and
 serviceproductions (stupid!!), and is inserted before storeTakList is
 called.
*/

takFilesDir('/home/leo/Documents/data/Eternal/development/takapicache').
%takFilesDir('/home/leo/Documents/data/Eternal/development/takapicache_short').


% Filter accepted Tps (for test)
%filterTak('SLL-QA').
filterTak(_).

% Pick up all connectionPoint files from the directory
readTakFiles :-
    taklibInit ,
%    removeTak,
    takFilesDir(Dir),
    atomic_list_concat([Dir, '*.connectionPoints.XX.json'], '/', Wild),
    expand_file_name(Wild, FileList),
    processCpFiles(FileList) .

% Open one file at a time
processCpFiles([]) :- ! .
processCpFiles([CpFile | Rest ]) :-
%   write(CpFile), nl,
    open(CpFile, read, Stream, [encoding(iso_latin_1)]) ,
    processCpFile(Stream),
    processCpFiles(Rest).

% Read the connection point file
processCpFile(Stream) :-

    json_read(Stream, CpListJson) ,
    processCpList(CpListJson),
    close(Stream) .

% Process one connectionPoint entry at a time
% Use it to find, and process, the cooperation and serviceProduction
% file for this connectionPoint and day
processCpList([]) :- ! .
processCpList([CpJson | Rest]) :-
    write(CpJson), nl ,
    % !!! Add check that the input is newer than the data in the db
    mkTypeFileName(cooperations, CpJson, CFileName),
    mkTypeFileName(serviceProductions, CpJson, SFileName),
    ! ,
    open(CFileName, read, Stream1, [encoding(utf8)]) ,
    readFileAddConnectionPoint(cooperation, Stream1, CpJson),
    close(Stream1),
    open(SFileName, read, Stream2, [encoding(utf8)]) ,
    readFileAddConnectionPoint(serviceProduction, Stream2, CpJson),
    close(Stream2),
    processCpList(Rest) .
processCpList([_CpJson | Rest]) :- % Catch and continue if a file doesn't exist
        processCpList(Rest) .

% Create file name and verify that it actually exist, and also that it
% is newer than the newest entry in the db
mkTypeFileName(Type, json(ConnectionPointList), CFileName) :-
    parseItemList(connectionPointList, ConnectionPointList, [Tp, SnapshotTime, Id]),
    isDataNewerThanDb(Tp, SnapshotTime),
    filterTak(Tp),
    takFilesDir(Dir),
    atomic_list_concat([Dir, '/*.', Type, '.', Id, '.json'], '', Wild),
    expand_file_name(Wild, [CFileName]).

% Process a cooperation/serviceProduction file and append the connection
% point to each item
readFileAddConnectionPoint(Type, Stream, CpJson) :-
    json_read(Stream, Json),
    appendToInnerJsonList(Json, CpJson, AppendedLists) ,
    atomic_list_concat([Type, 's'], '', PluralType) ,
    storeTakList(PluralType, AppendedLists).

appendToInnerJsonList( [], _CpJson, []) :- ! .
appendToInnerJsonList([json(Items)| Rest], CpJson, [json([connectionPoint=CpJson|Items]) | AppendedRest]) :-
    appendToInnerJsonList(Rest, CpJson, AppendedRest) .

isDataNewerThanDb(Tp, _SnapshotTime) :-         % Entry not exist = newer
    \+ currentTakDate(Tp, _Date) ,
    ! .
isDataNewerThanDb(Tp, SnapshotTime) :-
    currentTakDate(Tp, CurrentTakDate) ,
    sub_atom(SnapshotTime, 0, 10, _,  SnapshotDate),
    SnapshotDate @> CurrentTakDate .


/*************************************************************************
 * Store predicates, from JSON to facts in the Prolog database
*/

storeTakList(_, [] ) :- ! .

storeTakList(cooperations, [json(Cooperation) | Rest ]) :-
    sort(Cooperation,
         [
             connectionPoint=json(ConnectionPointList),
             _Id,
             logicalAddress=json(LogicalAddressList),
             serviceConsumer=json(ServiceComponentList),
             serviceContract=json(ServiceContractList)
         ]
        ),
    parseItemList(connectionPointList, ConnectionPointList, [Tp, SnapshotTime, _]),
    parseItemList(logicalAddressList, LogicalAddressList, [LogicalAddress, LogicalAddressDescription]) ,
    parseItemList(serviceComponentList, ServiceComponentList, [ServiceComponentHsaId, ServiceComponentDescription]) ,
    %parseItemList(serviceContractList, ServiceContractList, [Namespace, SwedishDomainShort, Major, Minor]) ,
    parseItemList(serviceContractList, ServiceContractList, [Namespace, Domain, Contract, MajorInNS, MajorInTak, Minor, SwedishDomainShort, RivType]) ,
    ! ,
    sub_atom(SnapshotTime, 0, 10, _,  SnapshotDate) ,
    storeConnectionPoint(connectionPoint(Tp, SnapshotDate)) ,
    storeBaseItem(logicalAddress, LogicalAddress, LogicalAddressDescription, origin(Tp, SnapshotTime)),
    storeBaseItem(serviceConsumer, ServiceComponentHsaId, ServiceComponentDescription, origin(Tp, SnapshotTime)) ,
    %storeBaseItem(serviceContract, Namespace, laValues(SwedishDomainShort, Major, Minor), origin(Tp, SnapshotTime)) ,
    storeBaseItem(serviceContract, Namespace, contractValues(Domain, Contract, MajorInNS, MajorInTak, Minor, SwedishDomainShort, RivType), origin(Tp, SnapshotTime)) ,
    storeCooperation(LogicalAddress, Namespace, ServiceComponentHsaId, Tp, SnapshotDate),
    storeTakList(cooperations, Rest).

storeTakList(serviceProductions, [json(ServiceProduction) | Rest ]) :-
    sort(ServiceProduction,
         [
             connectionPoint=json(ConnectionPointList),
             _Id,
             logicalAddress=json(LogicalAddressList),
             physicalAddress=Url,
             rivtaProfile=RivTaProfile,
             serviceContract=json(ServiceContractList),
             serviceProducer=json(ServiceComponentList)
         ]
        ),
    parseItemList(connectionPointList, ConnectionPointList, [Tp, SnapshotTime, _]),
    parseItemList(logicalAddressList, LogicalAddressList, [LogicalAddress, LogicalAddressDescription]) ,
    parseItemList(serviceComponentList, ServiceComponentList, [ServiceComponentHsaId, ServiceComponentDescription]) ,
    parseItemList(serviceContractList, ServiceContractList, [Namespace, Domain, Contract, MajorInNS, MajorInTak, Minor, SwedishDomainShort, RivType]) ,
    ! ,
    sub_atom(SnapshotTime, 0, 10, _,  SnapshotDate) ,
    storeConnectionPoint(connectionPoint(Tp, SnapshotDate)) ,
    storeBaseItem(logicalAddress, LogicalAddress, LogicalAddressDescription, origin(Tp, SnapshotTime)),
    storeBaseItem(serviceProducer, ServiceComponentHsaId, ServiceComponentDescription, origin(Tp, SnapshotTime)) ,
    storeBaseItem(serviceContract, Namespace, contractValues(Domain, Contract, MajorInNS, MajorInTak, Minor, SwedishDomainShort, RivType), origin(Tp, SnapshotTime)) ,
    storeServiceProduction(LogicalAddress, Namespace, ServiceComponentHsaId, Tp, Url, RivTaProfile, SnapshotDate),
    storeTakList(serviceProductions, Rest).

storeTakList(Type, [json(Item) | Rest ]) :-
    l_write_list(['*** Error, could not store ', Type]), nl,
    writeq(Item), nl,
    storeTakList(Type, Rest).


%-------------------------------------------------------------------

parseItemList(connectionPointList, ConnectionPointList, [Tp, SnapshotTime, Id]) :-
    sort(ConnectionPointList, [environment=Environment, id=Id, platform=Plattform, snapshotTime=SnapshotTime]),
    atomic_list_concat([Plattform, Environment], '-', Tp) ,
    ! .

parseItemList(logicalAddressList, LogicalAddressList, [Logicaladdress_Mapped, LogicalAddressDescription]) :-
    sort(LogicalAddressList, [description=LogicalAddressDescription, id=_, logicalAddress=LogicalAddress]) ,
    map_logicaladdress(LogicalAddress, Logicaladdress_Mapped) ,
    ! .
% There exist some LA without a description, default it to LA
parseItemList(logicalAddressList, LogicalAddressList, [Logicaladdress_Mapped, LogicalAddress]) :-
    sort(LogicalAddressList, [id=_, logicalAddress=LogicalAddress]) ,
    map_logicaladdress(LogicalAddress, Logicaladdress_Mapped) ,
    ! .

% ERROR [id=161,description=SLL - TakeCare AnpassningstjÃ¤nst,hsaId=TAKECAREADAPTER,connectionPoint=json([id=5,platform=SLL,environment=PROD,snapshotTime=2016-06-22T01:00:10+0200])]
parseItemList(serviceComponentList, ServiceComponentList, [HsaId, ServiceComponentDescription]) :-
    sort(ServiceComponentList, [description=ServiceComponentDescription, hsaId=HsaId, id=_]) ,
    ! .
% Some serviceComponent in serviceProductions/cooperations erronously contains a conenctionPoint item
parseItemList(serviceComponentList, ServiceComponentList, [HsaId, ServiceComponentDescription]) :-
    sort(ServiceComponentList, [connectionPoint=_, description=ServiceComponentDescription, hsaId=HsaId, id=_]) ,
    ! .

%ERROR [id=266,namespace=urn:riv:se.apotekensservice:or:HamtaOrdinationerPrivatpersonResponder:5,major=5,minor=0] - dvs SwesishDomainShort saknas
parseItemList(serviceContractList, ServiceContractList, [Namespace, Domain, Contract, MajorInNS, MajorInTak, Minor, SwedishDomainShort, RivType]) :-
    sort(ServiceContractList, [id=_, major=MajorInTak, minor=Minor, name=SwedishDomainShort, namespace=Namespace]) ,
    extractInfoFromNamespace(Namespace, Domain, Contract, MajorInNS, RivType) ,
    ! .

% Some contracts lack the filed "name"
parseItemList(serviceContractList, ServiceContractList, [Namespace, Domain, Contract, MajorInNS, MajorInTak, Minor,'*Svenskt namn saknas*', RivType]) :-
    sort(ServiceContractList, [id=_, major=MajorInTak, minor=Minor, namespace=Namespace]) ,
    extractInfoFromNamespace(Namespace, Domain, Contract, MajorInNS, RivType) ,
    ! .

parseItemList(Type, ItemList, _) :-
    l_write_list(['*** Error, could not parse ', Type]), nl,
    writeq(ItemList), nl ,
    fail.
%-------------------------------------------------------------------

%-------------------------------------------------------------------
% If this TP and date is already stored, do nothing. Otherwise store it
storeConnectionPoint(connectionPoint(Tp, SnapshotDate)) :-
    dbConnectionPoint(Tp, SnapshotDate) ,
    ! .
storeConnectionPoint(connectionPoint(Tp, SnapshotDate)) :-
    %( (retract( dbConnectionPoint( Tp, _)) , !) ; true ) ,
    assertz( dbConnectionPoint( Tp, SnapshotDate)) .

% Do nothing if the item already exist
storeBaseItem(Type, Key, Value, _Origin) :-
    dbBaseItem(Type, Key, Value, _Org) ,
    ! .
% If an item with the key doesn't exist - add it
storeBaseItem(Type, Key, Value, Origin) :-
    \+ dbBaseItem(Type, Key, _, _) ,
    ! ,
    assertz(dbBaseItem(Type, Key, Value, Origin)) .
% Source and target different and source i newer, or source has higher
% prio. Replace!
storeBaseItem(Type, Key, Value, origin(SourceTp, SourceSnapshotTime)) :-
    dbBaseItem(Type, Key, ValueTarget, OriginTarget) ,
    doReplaceItem(origin(SourceTp, SourceSnapshotTime), OriginTarget),
    ! ,
    %%%l_write_list(['Updated item: ', Type, nl, ' Key: ', Key, nl, ' New value: ', Value, nl,  ' Old value: ', ValueTarget, nl,  ' source: ', origin(SourceTp, SourceSnapshotTime), nl, ' target: ', OriginTarget, nl]),
    retract(dbBaseItem(Type, Key, ValueTarget, OriginTarget)) ,
    assertz(dbBaseItem(Type, Key, Value, origin(SourceTp, SourceSnapshotTime))),
    ! .
storeBaseItem(_,_,_,_) .


doReplaceItem(origin(_SourceTp, SourceSnapshotTime), origin(_TargetTp, TargetSnapshotTime)) :-
    sub_atom(SourceSnapshotTime, 0, 10, _,  SourceDate) ,
    sub_atom(TargetSnapshotTime, 0, 10, _,  TargetDate) ,
    SourceDate @> TargetDate ,
    ! .
doReplaceItem(origin(SourceTp, _SourceSnapshotTime), origin(TargetTp, _TargetSnapshotTime)) :-
    metaTpPrio(SourceTp, SourcePrio),
    metaTpPrio(TargetTp, TargetPrio),
    SourcePrio @< TargetPrio .

/*
    dbCooperation(_Key, LogicalAddress, Namespace,
    ServiceComponentHsaId, Tp, StartDate, EndDate),
 */
% If entry exist, only update the EndDate
% But, this logic doesn't take into account the fact that an EndDate can
% be set to an earlier date. Will not see if a cooperation is
% removed and then reinserted. Not good enough even if not that common.
% So, I should need to know what the currentUpdateDae was before this whole update started
/*
storeCooperation(LogicalAddress, Namespace, ServiceComponentHsaId, Tp, SnapshotDate) :-
    dbCooperation(Key, LogicalAddress, Namespace, ServiceComponentHsaId, Tp, StartDate, EndDate ),
    ! ,
    retract(dbCooperation(Key, LogicalAddress, Namespace, ServiceComponentHsaId, Tp, StartDate, EndDate)) ,
    assertz(dbCooperation(Key, LogicalAddress, Namespace, ServiceComponentHsaId, Tp, StartDate, SnapshotDate)).
% If entry does not exist - create it
storeCooperation(LogicalAddress, Namespace, ServiceComponentHsaId, Tp, SnapshotDate) :-
    l_counter_inc(dbCounter, Key),
    assertz(dbCooperation(Key, LogicalAddress, Namespace, ServiceComponentHsaId, Tp, SnapshotDate, SnapshotDate)).
*/

% Logic:
% 1. Check if the cooperation exist with end date equal LastTakDate. If it does:
%   a. Update it, store all info back except current date as end date
% 2. Otherwise
%   a. Add the cooperation with current date as bort start- and end date
% Todo: Verify that this item is not updated every day when the encoding is fixed and consistent
storeCooperation(LogicalAddress, Namespace, ServiceComponentHsaId, Tp, SnapshotDate) :-
    lastTakDate(Tp, LastTakDate) ,
    dbCooperation(Key, LogicalAddress, Namespace, ServiceComponentHsaId, Tp, StartDate, LastTakDate ),
    ! ,
    retract(dbCooperation(Key, LogicalAddress, Namespace, ServiceComponentHsaId, Tp, StartDate, LastTakDate)) ,
    assertz(dbCooperation(Key, LogicalAddress, Namespace, ServiceComponentHsaId, Tp, StartDate, SnapshotDate)).
% If entry does not exist - create it
storeCooperation(LogicalAddress, Namespace, ServiceComponentHsaId, Tp, SnapshotDate) :-
    l_counter_inc(dbCounter, Key),
    assertz(dbCooperation(Key, LogicalAddress, Namespace, ServiceComponentHsaId, Tp, SnapshotDate, SnapshotDate)).


% If entry exist, only update the EndDate
% Todo: Verify that this item is not updated every day when the encoding and URLs are fixed and consistent
storeServiceProduction(LogicalAddress, Namespace, ServiceComponentHsaId, Tp, Url, RivTaProfile, SnapshotDate) :-
    lastTakDate(Tp, LastTakDate) ,
    dbServiceProduction(Key, LogicalAddress, Namespace, ServiceComponentHsaId, Tp, Url, RivTaProfile, StartDate, LastTakDate),
    ! ,
    retract(dbServiceProduction(Key, LogicalAddress, Namespace, ServiceComponentHsaId, Tp, Url, RivTaProfile, StartDate, LastTakDate)) ,
    assertz(dbServiceProduction(Key, LogicalAddress, Namespace, ServiceComponentHsaId, Tp, Url, RivTaProfile, StartDate, SnapshotDate)) .
% If entry does not exist - create it
storeServiceProduction(LogicalAddress, Namespace, ServiceComponentHsaId, Tp, Url, RivTaProfile, SnapshotDate) :-
    l_counter_inc(dbCounter, Key),
    assertz(dbServiceProduction(Key, LogicalAddress, Namespace, ServiceComponentHsaId, Tp, Url, RivTaProfile, SnapshotDate, SnapshotDate)) .


removeTak :-
    l_counter_set(dbCounter, 0) ,
    retractall(dbConnectionPoint(_,_)) ,
    retractall(dbBaseItem(_,_,_,_)) ,
    retractall(dbCooperation(_,_,_,_,_,_,_)) ,
    retractall(dbServiceProduction(_,_,_,_,_,_,_,_,_)) .

/************************************************************************
 * Access predicates
 * *********************************************************************/
connectionPoint(Tp, SnapshotTime) :- currentTakDate(Tp, SnapshotTime) .

connectionPointSnapshot(Tp, SnapshotTime) :-
    dbConnectionPoint(Tp, SnapshotTime).

logicalAddress(LogicalAddess, LogicalAddressDescription) :-
    dbBaseItem(logicalAddress, LogicalAddess, LogicalAddressDescription, _Origin).




serviceConsumer(HsaId, Description) :- dbBaseItem(serviceConsumer, HsaId, Description, _Origin).

serviceProducer(HsaId, Description) :- dbBaseItem(serviceProducer, HsaId, Description, _Origin).

serviceComponent(HsaId, Description) :- serviceConsumer(HsaId, Description) .
serviceComponent(HsaId, Description) :- serviceProducer(HsaId, Description) .

serviceContract(Namespace, Domain, Contract, MajorInTak, Minor) :-
    serviceContract(Namespace, Domain, Contract, _MajorInNS, MajorInTak, Minor, _SwedishDomainShort, _RivType) .
serviceContract(Namespace, Domain, Contract, MajorInNS, MajorInTak, Minor, SwedishDomainShort, RivType) :-
    dbBaseItem(serviceContract, Namespace, contractValues(Domain, Contract, MajorInNS, MajorInTak, Minor, SwedishDomainShort, RivType), _Origin) .

% Rimligen plockas aktuellt datum upp, per TP, från connectionPoints-Snapshottime.

% OBS dbCooperation contains start- and enddates - not all dates there is
% cooperation is supposed to be called with a date, and it is checked if it is between the start- and enddate

% Remove all handling of current date calculations from all files except this lib!
cooperation(LogicalAddress, Namespace, ServiceComponentHsaId, Tp, Date) :-
    var(Date) ,
    ! ,
    currentTakDate(Tp, Date) ,
    cooperation(LogicalAddress, Namespace, ServiceComponentHsaId, Tp, Date) .
cooperation(LogicalAddress, Namespace, ServiceComponentHsaId, Tp, Date) :-
    dbCooperation(_Key, LogicalAddress, Namespace, ServiceComponentHsaId, Tp, StartDate, EndDate) ,
    Date    @>= StartDate , % nonvar(Date)
    EndDate @>= Date.

cooperation_period(Logical_Address, Namespace, Service_Component_Hsaid, Tp, period(Start_Date, End_Date)) :-
        dbCooperation(_Key, Logical_Address, Namespace, Service_Component_Hsaid, Tp, Start_Date, End_Date) .


serviceProduction(LogicalAddress, Namespace, ServiceComponentHsaId, Tp, Url, RivTaProfile, Date) :-
    var(Date) ,
    ! ,
    currentTakDate(Tp, Date) ,
    serviceProduction(LogicalAddress, Namespace, ServiceComponentHsaId, Tp, Url, RivTaProfile, Date) .
serviceProduction(LogicalAddress, Namespace, ServiceComponentHsaId, Tp, Url, RivTaProfile, Date) :-
    dbServiceProduction(_Key, LogicalAddress, Namespace, ServiceComponentHsaId, Tp, Url, RivTaProfile, StartDate, EndDate) ,
    Date    @>= StartDate ,
    EndDate @>= Date.

% The list of dates is extracted by combining start- and enddates from cooperations and productions.
% The list is unique and sorted in reverse chronological order
% Can be limited to a certain TP
% The Endate is updated to Snapshottime each time a TAK is loaded
updateDates(Tp, DateList) :-
    setof(StartDate,
        A^B^C^D^Tp^EndDate^dbCooperation(A, B, C, D, Tp, StartDate, EndDate) ,
        StartDateCoopList ) ,
    setof(EndDate,
        A^B^C^D^Tp^StartDate^dbCooperation(A, B, C, D, Tp, StartDate, EndDate) ,
        EndDateCoopList ) ,
    setof(StartDate,
        A^B^C^D^Tp^E^F^EndDate^dbServiceProduction(A, B, C, D, Tp, E, F, StartDate, EndDate) ,
        StartDateProdList ) ,
    setof(EndDate,
        A^B^C^D^Tp^E^F^StartDate^dbServiceProduction(A, B, C, D, Tp, E, F, StartDate, EndDate) ,
        EndDateProdList ) ,
    append([StartDateCoopList, EndDateCoopList, StartDateProdList, EndDateProdList], AllDateList) ,
    sort(AllDateList, AllDateListSorted) ,
    reverse(AllDateListSorted, DateList) .

updateDates(DateList) :- updateDates(_, DateList) .

% Simply pick the first date in the dates list
latestUpdateDate(Tp, Date) :-   updateDates(Tp, [Date | _Rest]) .
latestUpdateDate(Date) :-       updateDates(_Tp, [Date | _Rest]) .

% Returns a list of all dates for which a TAK has been read from the API
takDates(Tp, DateList) :-
    setof(SnapshotDate,
        connectionPointSnapshot(Tp, SnapshotDate) ,
        Dates ) ,
        reverse(Dates, DateList).

takDates(DateList) :- takDates(_, DateList) .

currentTakDate(Tp, Date) :- takDates(Tp, [Date | _Rest]) .

lastTakDate(Tp, LastDate) :- takDates(Tp, [_Current, LastDate | _Rest]) .

/***********************************************************************
 Managing predicates
 Export and import the TAK data.
*/

exportDb(FileName) :-
    open(FileName, write, Stream, []) ,
    exportDb2(Stream) ,
    close(Stream).

exportDb2(Stream) :-
    dbConnectionPoint(Tp, SnapshotTime),
    writeq(Stream, dbConnectionPoint(Tp, SnapshotTime)), write(Stream, '.'), nl(Stream) ,
    fail .
exportDb2(Stream) :-
    dbBaseItem(Type, LogicalAddess, LogicalAddressDescription, Origin) ,
    writeq(Stream, dbBaseItem(Type, LogicalAddess, LogicalAddressDescription, Origin)), write(Stream, '.'), nl(Stream) ,
    fail .
exportDb2(Stream) :-
    dbCooperation(Key, LogicalAddress, Namespace, ServiceComponentHsaId, Tp, StartDate, EndDate) ,
    writeq(Stream, dbCooperation(Key, LogicalAddress, Namespace, ServiceComponentHsaId, Tp, StartDate, EndDate)), write(Stream, '.'), nl(Stream) ,
    fail .
exportDb2(Stream) :-
    dbServiceProduction(Key, LogicalAddress, Namespace, ServiceComponentHsaId, Tp, Url, RivTaProfile, StartDate, EndDate) ,
    writeq(Stream, dbServiceProduction(Key, LogicalAddress, Namespace, ServiceComponentHsaId, Tp, Url, RivTaProfile, StartDate, EndDate)), write(Stream, '.'), nl(Stream) ,
    fail .
exportDb2(_Stream) .

importDb(FileName) :-
    removeTak ,
    load_files(FileName, [module(taklib)]) .

/*************************************************************************
* TAK library predicates
* ***********************************************************************/
extractInfoFromNamespace(Namespace, Domain, Contract, Major, RivType) :-
    atomic_list_concat([urn, RivType | List], ':', Namespace),
    reverse(List, [Major, ContractWithResponder | DomainReverseList]) ,
    extractContractName(ContractWithResponder, Contract) ,
    reverse(DomainReverseList, DomainList) ,
    atomic_list_concat(DomainList, ':', Domain) .

extractContractName(ContractWithResponder, Contract) :-
    atom_concat(Contract, 'Responder', ContractWithResponder) ,
    ! .
extractContractName(ContractWithoutResponder, ContractWithoutResponder) .
/*************************************************************************
 * Test predicates
 * **********************************************************************/
listChangedDates :-
    dbCooperation(Key1, LogicalAddress, Namespace, ServiceComponentHsaId, Tp, _StartDate1, EndDate1) ,
    dbCooperation(Key2, LogicalAddress, Namespace, ServiceComponentHsaId, Tp, _StartDate2, EndDate2) ,
    \+ EndDate1 = EndDate2 ,
    l_write_list([Key1, ' - ', Key2, nl]) .





