-module(saga_csv_nif).
-export([parse/2]).
-on_load(init/0).

init() ->
    SoName = case code:priv_dir(saga_csv) of
        {error, bad_name} ->
            %% Fallback: find priv/ relative to the beam file's directory
            BeamDir = filename:dirname(code:which(?MODULE)),
            PrivDir = filename:join(filename:dirname(BeamDir), "priv"),
            filename:join(PrivDir, saga_csv_nif);
        Dir ->
            filename:join(Dir, saga_csv_nif)
    end,
    erlang:load_nif(SoName, 0).

%% @doc Parse a single CSV row from a binary.
%%
%% Returns: [Status, BytesParsed | Fields]
%%   Status: ok | incomplete | open_quote
%%   BytesParsed: non_neg_integer()
%%   Fields: [binary()]
-spec parse(Delimiter :: non_neg_integer(), Data :: binary()) -> list().
parse(_Delimiter, _Data) ->
    exit(nif_library_not_loaded).
