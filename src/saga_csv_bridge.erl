-module(saga_csv_bridge).
-export([parse_row/2, parse_all/2, write_all/2]).

%% Parse a single row. Returns {ok, BytesParsed, Fields} | {incomplete, BytesParsed, Fields} | {open_quote, BytesParsed, Fields}
parse_row(Delimiter, Data) ->
    [Status, BytesParsed | Fields] = saga_csv_nif:parse(Delimiter, Data),
    {Status, BytesParsed, Fields}.

%% Parse all complete rows from a binary. Returns a list of rows (each row is a list of fields).
%% Delimiter can be a binary (e.g. <<",">>)  or an integer (e.g. 44).
parse_all(Delimiter, Data) when is_binary(Delimiter) ->
    <<DelByte, _/binary>> = Delimiter,
    parse_all(DelByte, Data, []);
parse_all(Delimiter, Data) when is_integer(Delimiter) ->
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

%% Write rows to CSV. Delimiter is a binary or integer.
%% Rows is a list of lists of binaries.
write_all(Delimiter, Rows) when is_binary(Delimiter) ->
    <<DelByte, _/binary>> = Delimiter,
    saga_csv_nif:write(DelByte, Rows);
write_all(Delimiter, Rows) when is_integer(Delimiter) ->
    saga_csv_nif:write(Delimiter, Rows).
