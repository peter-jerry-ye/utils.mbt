// Copyright 2024 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
fn index_to_char(index : Int, url_safe : Bool) -> Char {
  if index < 26 {
    Char::from_int(index + 65)
  } else if index < 52 {
    Char::from_int(index - 26 + 97)
  } else if index < 62 {
    Char::from_int(index - 52 + 48)
  } else if index == 62 {
    if url_safe {
      '-'
    } else {
      '+'
    }
  } else if url_safe {
    '_'
  } else {
    '/'
  }
}

///|
fn char_to_index(char : Char, url_safe : Bool) -> Int {
  let code = char.to_int()
  if code >= 65 && code <= 90 {
    code - 65
  } else if code >= 97 && code <= 122 {
    code - 97 + 26
  } else if code >= 48 && code <= 57 {
    code - 48 + 52
  } else if url_safe {
    if code == 45 {
      62
    } else {
      63
    }
  } else if code == 43 {
    62
  } else {
    63
  }
}

///|
struct Base64Encoder {
  mut i : Int
  mut buffer : Int
}

///|
pub fn Base64Encoder::new() -> Base64Encoder {
  { i: 0, buffer: 0 }
}

///|
pub fn encode(
  self : Base64Encoder,
  bytes : Iter[Byte],
  url_safe~ : Bool = false,
  padding~ : Bool = false
) -> Array[Char] {
  let result = Array::new()
  for byte in bytes {
    let byte = byte.to_int()
    match self.i % 3 {
      0 => {
        result.push(index_to_char(byte >> 2, url_safe))
        self.buffer = (byte & 0b11) << 4
      }
      1 => {
        result.push(index_to_char(self.buffer | (byte >> 4), url_safe))
        self.buffer = (byte & 0b1111) << 2
      }
      2 => {
        result.push(index_to_char(self.buffer | (byte >> 6), url_safe))
        result.push(index_to_char(byte & 0b111111, url_safe))
        self.buffer = 0
      }
      _ => panic()
    }
    self.i += 1
    self.i %= 3
  }
  if padding {
    match self.i % 3 {
      0 => ()
      1 => {
        result.push(index_to_char(self.buffer, url_safe))
        result.push('=')
        result.push('=')
      }
      2 => {
        result.push(index_to_char(self.buffer, url_safe))
        result.push('=')
      }
      _ => panic()
    }
    self.i = 0
  }
  result
}

///|
pub(open) trait Bytes_ {
  iter(Self) -> Iter[Byte]
}

///|
pub(open) trait Chars {
  iter(Self) -> Iter[Char]
}

///| Encode binary to ascii text following Base64 defined in RFC 4648
pub fn base64_encode[T : Bytes_](
  bytes : Iter[T],
  url_safe~ : Bool = false
) -> Iter[Char] {
  Iter::new(fn(f) {
    let state = Base64Encoder::new()
    for chunk in bytes {
      for ch in state.encode(chunk.iter(), url_safe~) {
        if f(ch) == IterEnd {
          return IterEnd
        }
      }
    } else {
      for ch in state.encode(Iter::empty(), url_safe~, padding=true) {
        if f(ch) == IterEnd {
          return IterEnd
        }
      } else {
        IterContinue
      }
    }
  })
}

///|
struct Base64Decoder {
  mut i : Int
  mut buffer : Int
}

///|
pub fn Base64Decoder::new() -> Base64Decoder {
  { i: 0, buffer: 0 }
}

///|
pub fn decode(
  self : Base64Decoder,
  input : Iter[Char],
  url_safe~ : Bool = false
) -> Array[Byte] {
  let result = []
  for ch in input {
    match self.i % 4 {
      0 => self.buffer = char_to_index(ch, url_safe) << 2
      1 => {
        let idx = char_to_index(ch, url_safe)
        result.push((self.buffer | (idx >> 4)).to_byte())
        self.buffer = (idx & 0b1111) << 4
      }
      2 =>
        if ch == '=' {
          return result
        } else {
          let idx = char_to_index(ch, url_safe)
          result.push((self.buffer | (idx >> 2)).to_byte())
          self.buffer = (idx & 0b11) << 6
        }
      3 =>
        if ch == '=' {
          return result
        } else {
          let idx = char_to_index(ch, url_safe)
          result.push((self.buffer | idx).to_byte())
          self.buffer = 0
        }
      _ => panic()
    }
    self.i += 1
    self.i %= 4
  }
  result
}

///| 
/// Decode ascii text to binary following Base64 defined in RFC 4648
///
/// If the string is not padded correctly, an empty `Bytes` will be returned
pub fn base64_decode[T : Chars](
  input : Iter[T],
  url_safe~ : Bool = false
) -> Iter[Byte] {
  let state = Base64Decoder::new()
  Iter::new(fn(f) {
    for ch in input {
      for byte in state.decode(ch.iter(), url_safe~) {
        if f(byte) == IterEnd {
          return IterEnd
        }
      }
    } else {
      IterContinue
    }
  })
}
