use csv_core::{ReadFieldResult, ReaderBuilder, WriteResult, WriterBuilder};
use rustler::{Binary, Encoder, Env, ListIterator, NewBinary, Term};

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
/// csv-core handles RFC 4180: quoting, escaping (""), configurable delimiter.
/// Fields are allocated as new BEAM binaries with quotes already stripped/unescaped.
#[rustler::nif]
fn parse<'a>(env: Env<'a>, delimiter: u8, data: Binary<'a>) -> Vec<Term<'a>> {
    let input = data.as_slice();
    let mut rdr = ReaderBuilder::new().delimiter(delimiter).build();

    let mut fields: Vec<Term<'a>> = Vec::new();
    let mut field_buf = vec![0u8; input.len().max(64)];
    let mut total_read = 0;

    loop {
        let (result, bytes_read, bytes_written) =
            rdr.read_field(&input[total_read..], &mut field_buf);
        total_read += bytes_read;

        match result {
            ReadFieldResult::InputEmpty => {
                // Last field of an incomplete row (no trailing newline)
                fields.push(make_binary(env, &field_buf[..bytes_written]));
                let mut out = vec![atoms::incomplete().encode(env), total_read.encode(env)];
                out.extend(fields);
                return out;
            }
            ReadFieldResult::Field { record_end } => {
                fields.push(make_binary(env, &field_buf[..bytes_written]));
                if record_end {
                    let mut out = vec![atoms::ok().encode(env), total_read.encode(env)];
                    out.extend(fields);
                    return out;
                }
            }
            ReadFieldResult::End => {
                // No more data at all
                if fields.is_empty() {
                    fields.push(make_binary(env, b""));
                }
                let mut out = vec![atoms::incomplete().encode(env), total_read.encode(env)];
                out.extend(fields);
                return out;
            }
            ReadFieldResult::OutputFull => {
                // Field larger than buffer — grow and retry from the start of this field.
                // This shouldn't happen often since we sized buf to input length.
                field_buf.resize(field_buf.len() * 2, 0);
                total_read -= bytes_read;
            }
        }
    }
}

fn make_binary<'a>(env: Env<'a>, bytes: &[u8]) -> Term<'a> {
    let mut bin = NewBinary::new(env, bytes.len());
    bin.as_mut_slice().copy_from_slice(bytes);
    let bin: Binary = bin.into();
    bin.encode(env)
}

/// Write CSV rows to a binary string.
///
/// Takes a delimiter byte and a list of rows, where each row is a list of binaries.
/// Returns a single binary with properly quoted/escaped CSV.
#[rustler::nif]
fn write<'a>(env: Env<'a>, delimiter: u8, rows: ListIterator<'a>) -> Term<'a> {
    let mut wtr = WriterBuilder::new().delimiter(delimiter).build();
    let mut out = Vec::with_capacity(1024);
    let mut field_buf = vec![0u8; 256];

    for row_term in rows {
        let fields: ListIterator = row_term.decode().expect("row must be a list");
        let mut first = true;
        for field_term in fields {
            let field: Binary = field_term.decode().expect("field must be a binary");
            if !first {
                loop {
                    let (result, bytes_written) = wtr.delimiter(&mut field_buf);
                    out.extend_from_slice(&field_buf[..bytes_written]);
                    match result {
                        WriteResult::InputEmpty => break,
                        WriteResult::OutputFull => {
                            field_buf.resize(field_buf.len() * 2, 0);
                        }
                    }
                }
            }
            first = false;
            let input = field.as_slice();
            let mut nin = 0;
            loop {
                let (result, bytes_read, bytes_written) = wtr.field(&input[nin..], &mut field_buf);
                nin += bytes_read;
                out.extend_from_slice(&field_buf[..bytes_written]);
                match result {
                    WriteResult::InputEmpty => break,
                    WriteResult::OutputFull => {
                        field_buf.resize(field_buf.len() * 2, 0);
                    }
                }
            }
        }
        // Write record terminator (\n) — also closes any open quotes
        loop {
            let (result, bytes_written) = wtr.terminator(&mut field_buf);
            out.extend_from_slice(&field_buf[..bytes_written]);
            match result {
                WriteResult::InputEmpty => break,
                WriteResult::OutputFull => {
                    field_buf.resize(field_buf.len() * 2, 0);
                }
            }
        }
    }

    make_binary(env, &out)
}

rustler::init!("saga_csv_nif");
