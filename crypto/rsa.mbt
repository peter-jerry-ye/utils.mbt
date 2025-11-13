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

// rfc8017

///|
pub(all) struct RSAPubKey {
  modulus : BigInt
  exponent : BigInt
  length : Int
}

///|
pub(all) enum RSAPrivKey {
  Pair(modulus~ : BigInt, exponent~ : BigInt, length~ : Int)
  Quintuple(
    factor1~ : BigInt,
    factor2~ : BigInt,
    exponent1~ : BigInt,
    exponent2~ : BigInt,
    coefficient~ : BigInt,
    triplets~ : Array[(BigInt, BigInt, BigInt)],
    length~ : Int
  )
}

///|
pub fn rsassa_pkcs1_v1_5_sign(
  bytes : Iter[Byte],
  priv_key : RSAPrivKey,
  hash? : HashAlgorithm = SHA256,
) -> BigInt {
  match priv_key {
    Pair(modulus~, exponent~, length~) => {
      let padded = emsa_pkcs1_v1_5(bytes, length / 8, hash~)
      let hex = BigInt::from_octets(padded)
      hex.pow(exponent, modulus~)
    }
    Quintuple(
      factor1=p,
      factor2=q,
      exponent1=dP,
      exponent2=dQ,
      coefficient=qInv,
      triplets~,
      length~
    ) => {
      let padded = emsa_pkcs1_v1_5(bytes, length / 8, hash~)
      let hex = BigInt::from_octets(padded)
      let ss = [
        hex.pow(dP, modulus=p),
        hex.pow(dQ, modulus=q),
        ..triplets.map(tuple => {
          guard tuple is (r, d, _)
          hex.pow(d, modulus=r)
        }),
      ]
      let h = (ss[0] - ss[1]) * qInv % p
      let h = if h < 0 { h + p } else { h }
      let mut s = ss[1] + q * h
      let mut r = p
      for i = 3; i < ss.length(); i = i + 1 {
        r += if i == 3 { q } else { triplets[i - 3].0 }
        let h = (ss[i - 1] - s) * triplets[i - 3].2 % r
        let h = if h < 0 { h + r } else { h }
        s += r * h
      }
      s
    }
  }
}

///|
pub fn rsassa_pkcs1_v1_5_verify(
  bytes : Iter[Byte],
  modulus : BigInt,
  exponent : BigInt,
  signature : BigInt,
  hash? : HashAlgorithm = SHA256,
  length? : Int = 2048,
) -> Bool {
  let padded = emsa_pkcs1_v1_5(bytes, length / 8, hash~)
  let number = BigInt::from_octets(padded)
  let decoded = signature.pow(exponent, modulus~)
  number == decoded
}

///|
fn emsa_pkcs1_v1_5(
  message : Iter[Byte],
  emLen : Int,
  hash? : HashAlgorithm = SHA256,
) -> Bytes {
  let h = hash.hash(message)
  let digest_info : X690 = {
    tag: Sequence,
    class: Universal,
    construction: Constructed,
    content: {
      let buffer = @buffer.new()
      buffer.write_bytes(hash.pkcs1_v1_5_digest_algorithms().to_bytes())
      buffer.write_bytes(
        {
          tag: OctetString,
          construction: Primitive,
          class: Universal,
          content: h,
        }.to_bytes(),
      )
      buffer.to_bytes()
    },
  }
  let t = digest_info.to_bytes()
  let tLen = t.length()
  if emLen < tLen + 11 {
    abort("intended encoded message length too short")
  }
  let ps = FixedArray::make(emLen - tLen - 3, b'\xff')
  let em = FixedArray::make(emLen, b'\x00')
  em[0] = b'\x00'
  em[1] = b'\x01'
  ps.blit_to(em, len=emLen - tLen - 3, dst_offset=2)
  em.blit_from_bytes(emLen - tLen, t, 0, tLen)
  Bytes::from_array(em)
}
