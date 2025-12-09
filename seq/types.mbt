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
struct T[A] {
  mut next : () -> A?
}

///|
/// Creates a new sequence from a function that generates the next element.
///
/// Parameters:
///
/// * `next` : A function that returns the next element in the sequence. Returns
/// `Some(element)` if there is a next element, or `None` if the sequence has
/// ended.
///
/// Returns a new sequence of type `T[A]` that will generate elements using the
/// provided function.
///
/// Example:
///
/// ```moonbit
/// let mut i = 0
/// let seq = T::new(fn() {
///   if i < 3 {
///     i = i + 1
///     Some(i)
///   } else {
///     None
///   }
/// })
/// inspect(seq.next(), content="Some(1)")
/// inspect(seq.next(), content="Some(2)")
/// inspect(seq.next(), content="Some(3)")
/// inspect(seq.next(), content="None")
/// ```
pub fn[A] T::new(next : () -> A?) -> T[A] {
  { next, }
}

///|
/// Returns the next element in the sequence, or `None` if the sequence is
/// exhausted. Each call to `next` advances the sequence to its next element.
///
/// Parameters:
///
/// * `self` : The sequence to get the next element from.
///
/// Returns an `Option` value that contains either the next element in the
/// sequence (`Some(value)`), or `None` if there are no more elements.
///
/// Example:
///
/// ```moonbit
/// let seq = T::from_array([1, 2, 3])
/// inspect(seq.next(), content="Some(1)")
/// inspect(seq.next(), content="Some(2)")
/// inspect(seq.next(), content="Some(3)")
/// inspect(seq.next(), content="None")
/// ```
pub fn[A] T::next(self : T[A]) -> A? {
  (self.next)()
}

///|
/// Checks if the sequence has more elements.
///
/// Parameters:
///
/// * `sequence` : The sequence to check. This is the receiver of the method
/// (`self`).
///
/// Returns `true` if the sequence has more elements to be retrieved, `false`
/// otherwise.
///
/// Example:
///
/// ```moonbit
/// let seq = T::from_array([1, 2, 3])
/// inspect(seq.has_next(), content="true")
/// let _ = seq.next()
/// inspect(seq.has_next(), content="true")
/// let _ = seq.next()
/// let _ = seq.next()
/// inspect(seq.has_next(), content="false")
/// ```
pub fn[A] T::has_next(self : T[A]) -> Bool {
  let { next } = self
  let next_val = next()
  self.next = fn() -> A? {
    self.next = next
    return next_val
  }
  next_val is Some(_)
}

///|
/// Creates an iterator from a sequence.
///
/// Parameters:
///
/// * `sequence` : The sequence to be converted to an iterator.
///
/// Returns an iterator that produces elements from the sequence in order.
///
/// Example:
///
/// ```moonbit
/// let seq = T::from_array([1, 2, 3])
/// let iter = seq.iter()
/// let buf = @buffer.new()
/// iter.each(fn(x) { buf.write_string(x.to_string()) })
/// inspect(buf.contents(), content=(
///   #|b"\x31\x00\x32\x00\x33\x00"
/// ))
/// ```
pub fn[A] T::iter(self : T[A]) -> Iter[A] {
  Iter::new(fn(visit) {
    loop self.next() {
      Some(value) => {
        guard IterContinue == visit(value) else { return IterEnd }
        continue self.next()
      }
      None => IterContinue
    }
  })
}

///|
/// Creates a sequence from an array.
///
/// Parameters:
///
/// * `array` : The source array to create the sequence from.
///
/// Returns a sequence (`T[A]`) that iterates through the elements of the array
/// in order.
///
/// Example:
///
/// ```moonbit
/// let array = [1, 2, 3]
/// let seq = T::from_array(array)
/// inspect(seq.next(), content="Some(1)")
/// inspect(seq.next(), content="Some(2)")
/// inspect(seq.next(), content="Some(3)")
/// inspect(seq.next(), content="None")
/// ```
pub fn[A] T::from_array(self : Array[A]) -> T[A] {
  let mut i = 0
  T::new(fn() {
    if i < self.length() {
      let val = self[i]
      i += 1
      Some(val)
    } else {
      None
    }
  })
}
