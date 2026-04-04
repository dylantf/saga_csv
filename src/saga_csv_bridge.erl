-module(saga_csv_bridge).
-export([parse_row/2, parse_all/2]).

%% Parse a single row. Returns {ok, BytesParsed, Fields} | {incomplete, BytesParsed, Fields} | {open_quote, BytesParsed, Fields}
parse_row(Delimiter, Data) ->
    [Status, BytesParsed | Fields] = saga_csv_nif:parse(Delimiter, Data),
    {Status, BytesParsed, Fields}.

%% Parse all complete rows from a binary. Returns a list of rows (each row is a list of fields).
parse_all(Delimiter, Data) ->
    parse_all(Delimiter, Data, []).

parse_all(_Delimiter, <<>>, Acc) ->
    lists:reverse(Acc);
parse_all(Delimiter, Data, Acc) ->
    [Status, BytesParsed | Fields] = saga_csv_nif:parse(Delimiter, Data),
    case Status of
        ok ->
            Rest = binary:part(Data, BytesParsed, byte_size(Data) - BytesParsed),
            parse_all(Delimiter, Rest, [Fields | Acc]);
        incomplete ->
            %% Last row without trailing newline — include it
            case Fields of
                [<<>>] -> lists:reverse(Acc);
                _ -> lists:reverse([Fields | Acc])
            end;
        open_quote ->
            {error, open_quote}
    end.
