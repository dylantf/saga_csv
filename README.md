# saga_csv

A fast CSV parser for [saga](https://github.com/dylantf/saga), powered by a Rust NIF.

The parser operates on raw binaries using zero-copy sub-binaries — parsed fields are views into the original input, not copies. This makes it fast enough for bulk data loading.

## Usage

```
import SagaCsv (parse)

let csv = "name,age,city\nAlice,30,Portland\nBob,25,Seattle\n"
let rows = parse 44 csv  # 44 = ASCII comma
# => [["name", "age", "city"], ["Alice", "30", "Portland"], ["Bob", "25", "Seattle"]]
```

The first argument to `parse` is the delimiter as an ASCII code (`44` for comma, `9` for tab, `59` for semicolon).

## Building

Requires Rust (cargo) and Erlang (erlc, rebar3) on PATH.

```bash
rebar3 compile    # builds the Rust NIF and Erlang bridge
saga build      # builds the saga library
saga run        # runs src/Main.dy
```

## Project structure

```
src/
  Main.dy               # example binary entry point
  saga_csv_nif.erl      # Erlang NIF loader
  saga_csv_bridge.erl   # Erlang bridge (type marshalling)
  saga_csv.app.src      # OTP application metadata
lib/
  SagaCsv.dy            # saga library module
native/
  Cargo.toml            # Rust NIF crate
  Makefile              # invoked by rebar3 pre_hooks
  src/lib.rs            # CSV parser implementation
```

## License

Apache-2.0
