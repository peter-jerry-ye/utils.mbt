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

///| Create a token based on RSA256
pub fn sign_rs256(payload : Json, private_key : String) -> String {
  // Prepare signature
  guard (private_key
    .split("\n")
    .drop(1)
    .take_while(fn(str) { not(str.has_prefix("----END")) })
    |> @codec.base64_decode
    |> @crypto.X690::from_iter
    |> Iter::collect)
    is [sequence]
  guard (sequence.content.iter()
    |> @crypto.X690::from_iter
    |> Iter::map(fn {
      { tag: Integer, construction: Primitive, class: Universal, content } =>
        BigInt::from_octets(content)
      _ => panic()
    })
    |> Iter::collect)
    is [
      _version,
      modulus,
      _public_exponent,
      _private_exponent,
      prime1,
      prime2,
      exponent1,
      exponent2,
      coefficient,
    ]
  let metadata = [
      @encoding.encode(
        UTF8,
        ({ "alg": "RS256", "typ": "JWT" } : Json) |> @json.stringify,
      ),
    ].iter()
    |> @codec.base64_encode(url_safe=true)
    |> Iter::filter(fn(ch) { ch != '=' }) // omit as per rfc7515 section 2
    |> String::from_iter
  let payload = [@encoding.encode(UTF8, payload |> @json.stringify)].iter()
    |> @codec.base64_encode(url_safe=true)
    |> Iter::filter(fn(ch) { ch != '=' }) // omit as per rfc7515 section 2
    |> String::from_iter
  let signature = @encoding.encode(UTF8, "\{metadata}.\{payload}").iter()
    |> @crypto.rsassa_pkcs1_v1_5_sign(
      Quintuple(
        factor1=prime1,
        factor2=prime2,
        exponent1~,
        exponent2~,
        coefficient~,
        triplets=[],
        length=modulus.to_octets().length() * 8,
      ),
    )
  let signature = [signature.to_octets()].iter()
    |> @codec.base64_encode(url_safe=true)
    |> Iter::filter(fn(ch) { ch != '=' }) // omit as per rfc7515 section 2
    |> String::from_iter
  "\{metadata}.\{payload}.\{signature}"
}
