-module(saga_csv_nif).
-export([parse/2]).
-on_load(init/0).

init() ->
    SoName = case code:priv_dir(saga_csv) of
        {error, bad_name} ->
            case filelib:is_dir(filename:join(["..", priv])) of
                true -> filename:join(["..", priv, saga_csv_nif]);
                _    -> filename:join([priv, saga_csv_nif])
            end;
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
