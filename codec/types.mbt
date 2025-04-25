// Copyright (c) 2025 peter-jerry-ye, International Digital Economy Academy
// utils is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//     http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

///|
pub(open) trait ByteSequence {
  iter(Self) -> Iter[Byte]
}

///|
fn &ByteSequence::empty() -> Iter[Byte] {
  Iter::empty()
}

///|
pub impl ByteSequence for Bytes with iter(self) {
  self.iter()
}

///|
pub impl ByteSequence for @buffer.T with iter(self) {
  self.iter()
}

///|
pub impl ByteSequence for Array[Byte] with iter(self) {
  self.iter()
}

///|
pub impl ByteSequence for FixedArray[Byte] with iter(self) {
  self.iter()
}

///|
pub impl ByteSequence for Iter[Byte] with iter(self) {
  self
}

///|
pub(open) trait CharSequence {
  iter(Self) -> Iter[Char]
}

///|
pub impl CharSequence for @string.View with iter(self) {
  self.iter()
}

///|
pub impl CharSequence for String with iter(self) {
  self.iter()
}

///|
pub impl CharSequence for Iter[Char] with iter(self) {
  self
}

///|
fn &CharSequence::empty() -> Iter[Char] {
  Iter::empty()
}
