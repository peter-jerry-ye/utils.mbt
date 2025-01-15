///|
fn to_hex_digit(value : Int) -> Char {
  match value {
    0..=9 => Char::from_int(value + 48)
    10..=15 => Char::from_int(value - 10 + 65)
    _ => panic()
  }
}

test {
  assert_eq!(to_hex_digit(0), '0')
  assert_eq!(to_hex_digit(1), '1')
  assert_eq!(to_hex_digit(2), '2')
  assert_eq!(to_hex_digit(3), '3')
  assert_eq!(to_hex_digit(4), '4')
  assert_eq!(to_hex_digit(5), '5')
  assert_eq!(to_hex_digit(6), '6')
  assert_eq!(to_hex_digit(7), '7')
  assert_eq!(to_hex_digit(8), '8')
  assert_eq!(to_hex_digit(9), '9')
  assert_eq!(to_hex_digit(10), 'A')
  assert_eq!(to_hex_digit(11), 'B')
  assert_eq!(to_hex_digit(12), 'C')
  assert_eq!(to_hex_digit(13), 'D')
  assert_eq!(to_hex_digit(14), 'E')
  assert_eq!(to_hex_digit(15), 'F')
}

///|
fn from_hex_digit(value : Char) -> Int {
  match value {
    '0'..='9' => value.to_int() - 48
    'a'..='f' => value.to_int() - 97 + 10
    'A'..='F' => value.to_int() - 65 + 10
    _ => panic()
  }
}

///| 
/// Encode a string into a URI-encoded string based on RFC 3986.
/// 
/// The assumption is that the char sequence contains code points.
pub fn uri_encode[T : CharSequence](
  chars : T,
  skip_gen_delims~ : Bool = false,
  skip_sub_delims~ : Bool = false
) -> String {
  let result = StringBuilder::new()
  for ch in chars {
    match ch {
      // unreserved = ALPHA / DIGIT / "-" / "." / "_" / "~"
      'A'..='Z' | 'a'..='z' | '0'..='9' | '-' | '_' | '.' | '~' =>
        result.write_char(ch)
      // gen-delims = ":" / "/" / "?" / "#" / "[" / "]" / "@"
      ':' | '/' | '?' | '#' | '[' | ']' | '@' =>
        if skip_gen_delims {
          result.write_char(ch)
        } else {
          result.write_char('%')
          result.write_char(ch.to_int() >> 4 |> to_hex_digit)
          result.write_char(ch.to_int() & 0xF |> to_hex_digit)
        }
      // sub-delims = "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="
      '!' | '$' | '&' | '\'' | '(' | ')' | '*' | '+' | ',' | ';' | '=' =>
        if skip_sub_delims {
          result.write_char(ch)
        } else {
          result.write_char('%')
          result.write_char(ch.to_int() >> 4 |> to_hex_digit)
          result.write_char(ch.to_int() & 0xF |> to_hex_digit)
        }
      _ => {
        result.write_char('%')
        result.write_char(ch.to_int() >> 4 |> to_hex_digit)
        result.write_char(ch.to_int() & 0xF |> to_hex_digit)
      }
    }
  }
  result.to_string()
}

test {
  inspect!(
    uri_encode("http://example.com/ ~user"),
    content="http%3A%2F%2Fexample.com%2F%20~user",
  )
}

///|
pub fn uri_decode[T : CharSequence](
  chars : T,
  stream~ : Bool = false
) -> String! {
  let mut buffer = 0
  let mut state = 0
  let result = StringBuilder::new()
  for ch in chars {
    match state {
      0 =>
        match ch {
          '%' => state = 1
          _ => result.write_char(ch)
        }
      1 => {
        buffer = from_hex_digit(ch) << 4
        state = 2
      }
      2 => {
        buffer = buffer | from_hex_digit(ch)
        result.write_char(buffer |> Char::from_int())
        buffer = 0
        state = 0
      }
      _ => panic()
    }
  } else {
    if state == 0 || stream {
      result.to_string()
    } else {
      fail!("Invalid URI encoding")
    }
  }
}

test {
  inspect!(
    uri_decode!("http%3A%2F%2Fexample.com%2F%20~user"),
    content="http://example.com/ ~user",
  )
}
