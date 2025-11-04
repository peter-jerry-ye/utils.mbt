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
struct Immut[A](() -> (A?, Immut[A]))

///|
/// Creates a new immutable sequence from a generator function.
///
/// Parameters:
///
/// * `next` : A generator function that produces the next element and the next
/// sequence state. The function returns a tuple where the first element is an
/// `Option` containing the next value (or `None` if the sequence is exhausted),
/// and the second element is the next immutable sequence state.
///
/// Returns an immutable sequence that will generate elements using the provided
/// generator function.
///
/// Example:
///
/// ```moonbit
/// let seq : Immut[Int] = Immut::new(fn() -> (Int?, Immut[Int]) {
///   let empty : Immut[Int] = Immut::empty()
///   (Some(1), empty)
/// })
/// inspect(seq.next(), content="Some(1)")
/// inspect(seq.next(), content="Some(1)")
/// ```
pub fn[A] Immut::new(next : () -> (A?, Immut[A])) -> Immut[A] {
  next
}

///|
/// Returns the next element in the immutable sequence without advancing the
/// sequence state.
///
/// Parameters:
///
/// * `sequence` : The immutable sequence to get the next element from.
///
/// Returns an `Option` value that contains either the next element in the
/// sequence (`Some(value)`), or `None` if there are no more elements.
///
/// Example:
///
/// ```moonbit
/// let seq = Immut::from_array([1, 2, 3])
/// inspect(seq.next(), content="Some(1)")
/// inspect(seq.next(), content="Some(1)") // Same value since state is preserved
/// ```
pub fn[A] Immut::next(self : Immut[A]) -> A? {
  self().0
}

///|
/// Advances an immutable sequence to its next state without consuming the
/// current element.
///
/// Parameters:
///
/// * `sequence` : The immutable sequence to advance. This is received as `self`
/// in the method.
///
/// Returns a new immutable sequence representing the next state of the sequence.
/// Since the sequence is immutable, the original sequence remains unchanged.
///
/// Example:
///
/// ```moonbit
/// let seq = Immut::from_array([1, 2, 3])
/// inspect(seq.next(), content="Some(1)")
/// let next_seq = seq.step()
/// inspect(next_seq.next(), content="Some(2)")
/// inspect(seq.next(), content="Some(1)") // Original sequence unchanged
/// ```
pub fn[A] Immut::step(self : Immut[A]) -> Immut[A] {
  self().1
}

///|
/// Checks if the immutable sequence has more elements without consuming them.
/// Unlike regular sequences, immutable sequences preserve their state between
/// calls.
///
/// Parameters:
///
/// * `sequence` : The immutable sequence to check. This is the receiver of the
/// method (`self`).
///
/// Returns `true` if the sequence has more elements to be retrieved, `false`
/// otherwise.
///
/// Example:
///
/// ```moonbit
/// let seq = Immut::from_array([1, 2, 3])
/// inspect(seq.has_next(), content="true")
/// let _ = seq.next()
/// inspect(seq.has_next(), content="true") // State is preserved
/// ```
pub fn[A] Immut::has_next(self : Immut[A]) -> Bool {
  let (next_val, _) = self()
  not(next_val.is_empty())
}

///|
pub fn[A] Immut::iter(self : Immut[A]) -> Iter[A] {
  Iter::new(fn(visit) {
    loop self() {
      (Some(val), next) => {
        guard IterContinue == visit(val) else { return IterEnd }
        continue next()
      }
      (None, _) => IterContinue
    }
  })
}

///|
/// Creates an immutable sequence from an array.
///
/// Parameters:
///
/// * `array` : The source array to create the sequence from. The type of
/// elements in the array can be any type `A`.
///
/// Returns an immutable sequence (`Immut[A]`) that iterates through the elements
/// of the array in order. The sequence maintains its immutability by creating
/// new state for each iteration.
///
/// Example:
///
/// ```moonbit
/// let array = [1, 2, 3]
/// let seq = Immut::from_array(array)
/// inspect(seq.next(), content="Some(1)")
/// inspect(seq.next(), content="Some(1)")
/// inspect(seq.next(), content="Some(1)")
/// ```
pub fn[A] Immut::from_array(self : Array[A]) -> Immut[A] {
  fn f(i) {
    match self.get(i) {
      Some(val) => (Some(val), Immut::new(fn() { f(i + 1) }))
      None => (None, Immut::empty())
    }
  }

  Immut::new(fn() { f(0) })
}

///|
/// Creates an empty immutable sequence that never produces any elements.
///
/// Parameters:
///
/// * `A` : The type parameter representing the type of elements that would be in
/// the sequence (though the sequence will always be empty).
///
/// Returns an empty immutable sequence (`Immut[A]`) that returns `None` for
/// every call to `next()`.
///
/// Example:
///
/// ```moonbit
/// let seq : Immut[Int] = Immut::empty()
/// inspect(seq.next(), content="None")
/// inspect(seq.has_next(), content="false")
/// ```
pub fn[A] Immut::empty() -> Immut[A] {
  let iter : Ref[Immut[A]?] = { val: None }
  iter.val = Some(Immut::new(fn() { (None, iter.val.unwrap()) }))
  iter.val.unwrap()
}
