-module(lte).

-behaviour(application).

-define(APP, lte).

%% Application callbacks
-export([start/2, stop/1, start_phase/3]).

-export([config/0, config/1, config/2,
         start/0, a_start/2]).

 -include_lib("lte_model/include/node_logger.hrl").

%-define(TEST,true).
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.


%%%===================================================================
%%% Convenience Functions
%%%===================================================================

start() ->
    ?INFO("Start LTE application"),
    a_start(?APP, permanent).

config(Key, Default) ->
    case application:get_env(?APP, Key) of
        undefined -> Default;
        {ok, Val} -> Val
    end.

config(Key) ->
    case application:get_env(?APP, Key) of
        undefined -> erlang:error({missing_config, Key});
        {ok, Val} -> Val
    end.

config() ->
    application:get_all_env(?APP).


%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    lte_sup:start_link().

stop(_State) ->
    ok.

start_phase(listen, _Type, _Args) ->
    ?INFO("Start LTE phase: listen"),
    %% Dispatch = [{'_', [
    %%                    {'_', ef_http_handler, []}
    %%                   ]}
    %%            ],
    %% cowboy:start_listener(http, 100, cowboy_tcp_transport,
    %%                       [{port, config(http_port)}],
    %%                       cowboy_http_protocol,
    %%                       [{dispatch, Dispatch}]
    %%                      ),
    ok.

%%%===================================================================
%%% Internal functions
%%%===================================================================

a_start(App, Type) ->
    start_ok(App, Type, application:start(App, Type)).

start_ok(_App, _Type, ok) -> ok;
start_ok(_App, _Type, {error, {already_started, _App}}) -> ok;
start_ok(App, Type, {error, {not_started, Dep}}) ->
    ok = a_start(Dep, Type),
    a_start(App, Type);
start_ok(App, _Type, {error, Reason}) ->
    erlang:error({app_start_failed, App, Reason}).

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------

encode_mac_pdu(UeId, Rnti, PDU) ->
    <<UeId:32/integer, Rnti:32/integer, PDU/bitstring>>.

decode_mac_pdu(Data) -> 
    <<UeId:32/integer, Rnti:32/integer, PDU/bitstring>> = Data,
    {UeId, Rnti, PDU}.

-ifdef(TEST).
mac_pdu_test() ->
    UeId=42, Rnti=103, PDU= <<"Hello">>,
    Data = encode_mac_pdu(UeId, Rnti, PDU),
    {UeId1, Rnti1, PDU} = decode_mac_pdu(Data),
    ?assertEqual(UeId, UeId1),
    ?assertEqual(Rnti, Rnti1).
    
-endif.
