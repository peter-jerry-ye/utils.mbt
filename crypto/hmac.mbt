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

// rfc2104

///|
pub fn hmac(
  content : Iter[Byte],
  hash~ : HashAlgorithm,
  secret~ : Bytes
) -> Bytes {
  // block length of the hash function
  // TODO: it may not be 64 for all hash algorithms
  let b = 64
  let k = if secret.length() > b { hash.hash(secret.iter()) } else { secret }
  let ipad = k.iter() + Bytes::new(b - k.length()).iter()
    |> Iter::map(fn(i) { i ^ b'\x36' })
  let out = hash.hash(ipad + content)
  let opad = k.iter() + Bytes::new(b - k.length()).iter()
    |> Iter::map(fn(i) { i ^ b'\x5C' })
  hash.hash(opad + out.iter())
}

///|
test "hmac" {
  inspect!(
    hmac(
      b"I would like to buy 100 units.".iter(),
      hash=HashAlgorithm::MD5,
      secret=b"666",
    )
    |> BigInt::from_octets
    |> BigInt::to_hex,
    content="76320C555FF8979F16DF9539E53D4B69",
  )
  inspect!(
    hmac(
      b"A quick brown fox jumps over the lazy dog".iter(),
      hash=HashAlgorithm::SHA224,
      secret=b"12345678901234567890123456789012",
    )
    |> BigInt::from_octets
    |> BigInt::to_hex,
    content="870650B1A3FDB1318C93CCAFAC0F248DC356414E9FEADF5E0F268FCF",
  )
  inspect!(
    hmac(
      b"A quick brown fox jumps over the lazy dog".iter(),
      hash=HashAlgorithm::SHA256,
      secret=b"I am a secret",
    )
    |> BigInt::from_octets
    |> BigInt::to_hex,
    content="B7F4909B7EEE9F77A34BB0144864222B8AB6AE3CE1500161BAEBED411AA451EA",
  )
}
