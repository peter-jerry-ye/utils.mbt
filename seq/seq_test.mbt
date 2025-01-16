// Copyright (c) 2025 peter-jerry-ye, International Digital Economy Academy
// utils is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//     http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

test {
  let a = T::from_array([1, 2, 3])
  inspect!(a.next(), content="Some(1)")
  if a.has_next() {
    inspect!(a.next(), content="Some(2)")
  }
  inspect!(a.next(), content="Some(3)")
  let b = Immut::from_array([1, 2, 3])
  inspect!(b.next(), content="Some(1)")
  if b.has_next() {
    inspect!(b.next(), content="Some(1)")
  }
  inspect!(b.next(), content="Some(1)")
  let c = b.step()
  inspect!(c.next(), content="Some(2)")
  inspect!(b.next(), content="Some(1)")
}

test {
  let a = T::from_array([1, 2, 3])
  inspect!(a.iter().collect(), content="[1, 2, 3]")
  let b = Immut::from_array([1, 2, 3])
  inspect!(b.iter().collect(), content="[1, 2, 3]")
}
