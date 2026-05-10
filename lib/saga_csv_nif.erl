-module(saga_csv_nif).
-export([parse/2, write/2]).
-on_load(init/0).

init() ->
    SoName = case code:priv_dir(saga_csv) of
        {error, bad_name} ->
            %% Fallback: search for priv/ relative to the beam file's directory.
            %% Beam may be in _build/dev/ while priv/ is at the project root.
            BeamDir = filename:dirname(code:which(?MODULE)),
            {ok, Cwd} = file:get_cwd(),
            find_priv([
                filename:join(filename:dirname(BeamDir), "priv"),              %% ../priv (dep in _build/)
                filename:join(filename:dirname(filename:dirname(BeamDir)), "priv"),  %% ../../priv (project _build/dev/)
                filename:join(Cwd, "priv"),                                    %% ./priv (running from project root)
                filename:join([Cwd, "deps", "saga_csv", "priv"])               %% deps/saga_csv/priv (as dependency)
            ]);
        Dir ->
            filename:join(Dir, saga_csv_nif)
    end,
    erlang:load_nif(SoName, 0).

find_priv([]) ->
    error(nif_priv_dir_not_found);
find_priv([Candidate | Rest]) ->
    SoPath = filename:join(Candidate, saga_csv_nif),
    case filelib:is_file(SoPath ++ ".so") orelse filelib:is_file(SoPath ++ ".dll") of
        true -> SoPath;
        false -> find_priv(Rest)
    end.

%% @doc Parse a single CSV row from a binary.
%%
%% Returns: [Status, BytesParsed | Fields]
%%   Status: ok | incomplete | open_quote
%%   BytesParsed: non_neg_integer()
%%   Fields: [binary()]
-spec parse(Delimiter :: non_neg_integer(), Data :: binary()) -> list().
parse(_Delimiter, _Data) ->
    exit(nif_library_not_loaded).

-spec write(Delimiter :: non_neg_integer(), Rows :: [[binary()]]) -> binary().
write(_Delimiter, _Rows) ->
    exit(nif_library_not_loaded).
