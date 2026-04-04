use rustler::{Binary, Encoder, Env, Term};

mod atoms {
    rustler::atoms! {
        ok,
        incomplete,
        open_quote,
    }
}

/// Parse a single CSV row from a binary.
///
/// Returns a list: [status, bytes_parsed, field1, field2, ...]
///   status: ok (complete row), incomplete (no newline yet), open_quote (unterminated quote)
///   bytes_parsed: how many bytes were consumed from the input
///
/// Fields are zero-copy sub-binaries of the input — no data is copied.
#[rustler::nif]
fn parse<'a>(env: Env<'a>, delimiter: u8, data: Binary<'a>) -> Vec<Term<'a>> {
    let bytes = data.as_slice();
    let mut fields: Vec<Term<'a>> = Vec::new();
    let mut field_start = 0;
    let mut pos = 0;
    let mut in_quotes = false;
    let len = bytes.len();

    while pos < len {
        let b = bytes[pos];

        if in_quotes {
            if b == b'"' {
                if pos + 1 < len && bytes[pos + 1] == b'"' {
                    pos += 2;
                } else {
                    in_quotes = false;
                    pos += 1;
                }
            } else {
                pos += 1;
            }
        } else if b == b'"' && pos == field_start {
            in_quotes = true;
            pos += 1;
        } else if b == delimiter {
            fields.push(sub_binary(env, &data, field_start, pos));
            pos += 1;
            field_start = pos;
        } else if b == b'\n' {
            fields.push(sub_binary(env, &data, field_start, pos));
            pos += 1;
            let mut result = vec![atoms::ok().encode(env), pos.encode(env)];
            result.extend(fields);
            return result;
        } else if b == b'\r' && pos + 1 < len && bytes[pos + 1] == b'\n' {
            fields.push(sub_binary(env, &data, field_start, pos));
            pos += 2;
            let mut result = vec![atoms::ok().encode(env), pos.encode(env)];
            result.extend(fields);
            return result;
        } else {
            pos += 1;
        }
    }

    fields.push(sub_binary(env, &data, field_start, pos));

    let status = if in_quotes {
        atoms::open_quote()
    } else {
        atoms::incomplete()
    };

    let mut result = vec![status.encode(env), pos.encode(env)];
    result.extend(fields);
    result
}

/// Zero-copy sub-binary: returns a view into the original binary from `start` to `end`.
fn sub_binary<'a>(env: Env<'a>, data: &Binary<'a>, start: usize, end: usize) -> Term<'a> {
    let sub = data.make_subbinary(start, end - start)
        .expect("sub-binary bounds error");
    sub.encode(env)
}

rustler::init!("saga_csv_nif");
