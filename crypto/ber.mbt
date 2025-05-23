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

// X.690 encoding format

///|
pub(all) enum X690Construction {
  Primitive
  Constructed
} derive(Show)

///|
pub(all) enum X690Class {
  Universal
  Application
  ContextSpecific
  Private
} derive(Show)

///|
fn X690Construction::from_int(value : Int) -> X690Construction {
  match value {
    0 => Primitive
    1 => Constructed
    _ => panic()
  }
}

///|
fn X690Construction::to_int(self : X690Construction) -> Int {
  match self {
    Primitive => 0
    Constructed => 1
  }
}

///|
fn X690Class::from_int(value : Int) -> X690Class {
  match value {
    0 => Universal
    1 => Application
    2 => ContextSpecific
    3 => Private
    _ => panic()
  }
}

///|
fn X690Class::to_int(self : X690Class) -> Int {
  match self {
    Universal => 0
    Application => 1
    ContextSpecific => 2
    Private => 3
  }
}

///|
pub(all) enum X690Type {
  Boolean
  Integer
  BitString
  OctetString
  Null
  ObjectIdentifier
  ObjectDescriptor
  External
  Real
  Enumerated
  EmbeddedPDV
  UTF8String
  RelativeOID
  Time
  Sequence
  Set
  NumericString
  PrintableString
  TeletexString
  VideotexString
  IA5String
  UTCTime
  GeneralizedTime
  GraphicString
  VisibleString
  GeneralString
  UniversalString
  CharacterString
  BMPString
  Date
  TimeOfDay
  DateTime
  Duration
  OID_IRI
  Relative_OID_IRI
} derive(Show)

///|
fn X690Type::from_int(value : Int) -> X690Type {
  match value {
    1 => Boolean
    2 => Integer
    3 => BitString
    4 => OctetString
    5 => Null
    6 => ObjectIdentifier
    7 => ObjectDescriptor
    8 => External
    9 => Real
    10 => Enumerated
    11 => EmbeddedPDV
    12 => UTF8String
    13 => RelativeOID
    14 => Time
    16 => Sequence
    17 => Set
    18 => NumericString
    19 => PrintableString
    20 => TeletexString
    21 => VideotexString
    22 => IA5String
    23 => UTCTime
    24 => GeneralizedTime
    25 => GraphicString
    26 => VisibleString
    27 => GeneralString
    28 => UniversalString
    29 => CharacterString
    30 => BMPString
    31 => Date
    32 => TimeOfDay
    33 => DateTime
    34 => Duration
    35 => OID_IRI
    36 => Relative_OID_IRI
    _ => panic()
  }
}

///|
fn X690Type::to_int(self : X690Type) -> Int {
  match self {
    Boolean => 1
    Integer => 2
    BitString => 3
    OctetString => 4
    Null => 5
    ObjectIdentifier => 6
    ObjectDescriptor => 7
    External => 8
    Real => 9
    Enumerated => 10
    EmbeddedPDV => 11
    UTF8String => 12
    RelativeOID => 13
    Time => 14
    Sequence => 16
    Set => 17
    NumericString => 18
    PrintableString => 19
    TeletexString => 20
    VideotexString => 21
    IA5String => 22
    UTCTime => 23
    GeneralizedTime => 24
    GraphicString => 25
    VisibleString => 26
    GeneralString => 27
    UniversalString => 28
    CharacterString => 29
    BMPString => 30
    Date => 31
    TimeOfDay => 32
    DateTime => 33
    Duration => 34
    OID_IRI => 35
    Relative_OID_IRI => 36
  }
}

///|
pub(all) struct X690 {
  tag : X690Type
  construction : X690Construction
  class : X690Class
  content : Bytes
} derive(Show)

///|
priv struct Tag {
  tag : Int
  class : X690Class
  construction : X690Construction
}

///|
priv enum State {
  Init
  Tag(ty~ : Int, X690Construction, X690Class)
  Length(Tag, mut len~ : Int, mut cnt~ : Int?)
  Content(Tag, @buffer.Buffer, mut len~ : Int?, mut end_cnt~ : Int)
}

///|
fn variable_length_encoding(buffer : @buffer.T, number : UInt) -> Unit {
  let number = number
  let len = 32 - number.clz()
  let mod = len % 7
  let n = len / 7
  if mod != 0 && n == 0 {
    buffer.write_byte(number.to_byte())
    return
  } else if mod != 0 {
    buffer.write_byte((number >> (n * 7)) | 0b1000_0000 |> UInt::to_byte)
  }
  for i = n - 1; i > 0; i = i - 1 {
    buffer.write_byte(
      ((number >> (i * 7)) & 0b111_1111) | 0b1000_0000 |> UInt::to_byte,
    )
  } else {
    buffer.write_byte((number & 0b111_1111) | 0b0000_0000 |> UInt::to_byte)
  }
}

///|
test "variable length encoding" {
  let buffer = @buffer.new()
  variable_length_encoding(buffer, 311)
  inspect!(
    buffer.to_bytes(),
    content=
      #|b"\x82\x37"
    ,
  )
  let buffer = @buffer.new()
  variable_length_encoding(buffer, 50)
  inspect!(
    buffer.to_bytes(),
    content=
      #|b"\x32"
    ,
  )
}

///|
pub fn oid_to_bytes(tree : Array[Int]) -> Bytes {
  let buffer = @buffer.new()
  guard tree is [first, second, .. rest]
  buffer.write_byte((first * 40 + second).to_byte())
  for value in rest {
    variable_length_encoding(buffer, value.reinterpret_as_uint())
  }
  buffer.to_bytes()
}

///| Assuming length is definite
pub fn to_bytes(self : X690) -> Bytes {
  let buffer = @buffer.new()
  if self.tag.to_int() < 30 {
    buffer.write_byte(
      self.tag.to_int() |
      (self.construction.to_int() << 5) |
      (self.class.to_int() << 6)
      |> Int::to_byte,
    )
  } else {
    buffer.write_byte(
      0b0001_1111 |
      (self.construction.to_int() << 5) |
      (self.class.to_int() << 6)
      |> Int::to_byte,
    )
    variable_length_encoding(buffer, self.tag.to_int().reinterpret_as_uint())
  }
  let length = self.content.length().reinterpret_as_uint()
  let length_len = 32 - length.clz()
  if length_len < 8 {
    buffer.write_byte(length.to_byte())
  } else {
    let mod = length_len % 8
    let n = length_len / 8
    let len = if mod == 0 { n } else { n + 1 }
    buffer.write_byte((0b1000_0000 | len).to_byte())
    for i = len - 1; i >= 0; i = i - 1 {
      buffer.write_byte(((length >> (i * 8)) & 0xff).to_byte())
    }
  }
  buffer.write_bytes(self.content)
  buffer.to_bytes()
}

///|
test "OID and x690 to bytes" {
  let pkcs_1 = X690::{
    tag: ObjectIdentifier,
    construction: Primitive,
    class: Universal,
    content: oid_to_bytes([1, 2, 840, 113549, 1, 1]),
  }
  inspect!(
    pkcs_1.to_bytes(),
    content=
      #|b"\x06\x08\x2a\x86\x48\x86\xf7\x0d\x01\x01"
    ,
  )
}

///|
pub fn X690::from_iter(bytes : Iter[Byte]) -> Iter[X690] {
  Iter::new(fn(f) {
    let mut state = Init
    for byte in bytes {
      match state {
        Init => {
          let byte = byte.to_int()
          let construction = if (byte & 0b0010_0000) == 0 {
            Primitive
          } else {
            Constructed
          }
          let class = match byte >> 6 {
            0 => Universal
            1 => Application
            2 => ContextSpecific
            3 => Private
            _ => break IterEnd
          }
          let tag = byte & 0b0001_1111
          if tag == 0b0001_1111 {
            state = Tag(ty=0, construction, class)
          } else {
            state = Length({ tag, construction, class }, len=0, cnt=None)
          }
        }
        Tag(ty~, construction, class) => {
          let ty = (ty << 7) | (byte.to_int() & 0b0111_1111)
          if (byte.to_int() & 0b1000_0000) == 0 {
            state = Length({ tag: ty, construction, class }, len=0, cnt=None)
          } else {
            state = Tag(ty~, construction, class)
          }
        }
        Length(tag, cnt=None, ..) as len_state =>
          if (byte.to_int() & 0b1000_0000) == 0 {
            state = Content(
              tag,
              @buffer.new(),
              len=Some(byte.to_int()),
              end_cnt=0,
            )
          } else {
            let n = byte.to_int() & 0b0111_1111
            if n == 0 {
              state = Content(tag, @buffer.new(), len=None, end_cnt=0)
            } else {
              len_state.cnt = Some(n)
            }
          }
        Length(tag, len~, cnt=Some(n)) as len_state => {
          len_state.len = (len << 8) | byte.to_int()
          len_state.cnt = Some(n - 1)
          if n == 1 {
            state = Content(
              tag,
              @buffer.new(),
              len=Some(len_state.len),
              end_cnt=0,
            )
          }
        }
        Content(tag, buf, len=None, ..) as content_state =>
          if byte == b'\x00' {
            content_state.end_cnt += 1
            if content_state.end_cnt == 2 {
              if f({
                  tag: tag.tag |> X690Type::from_int,
                  construction: tag.construction,
                  class: tag.class,
                  content: buf.to_bytes(),
                }) ==
                IterEnd {
                return IterEnd
              }
              state = Init
            }
          } else {
            buf.write_byte(byte)
          }
        Content(tag, buf, len=Some(len), ..) as content_state => {
          buf.write_byte(byte)
          content_state.len = Some(len - 1)
          if len == 1 {
            if f({
                tag: tag.tag |> X690Type::from_int,
                construction: tag.construction,
                class: tag.class,
                content: buf.to_bytes(),
              }) ==
              IterEnd {
              return IterEnd
            }
            state = Init
          }
        }
      }
    } else {
      IterContinue
    }
  })
}

///|
test "decode pem file" {
  // Copied from https://www.hanselman.com/blog/decoding-an-ssh-key-from-pem-to-base64-to-hex-to-asn1-to-prime-decimal-numbers
  let key =
    #|MIIEpAIBAAKCAQEAtd8As85sOUjjkjV12ujMIZmhyegXkcmGaTWk319vQB3+cpIh
    #|Wu0mBke8R28jRym9kLQj2RjaO1AdSxsLy4hR2HynY7l6BSbIUrAam/aC/eVzJmg7
    #|qjVijPKRTj7bdG5dYNZYSEiL98t/+XVxoJcXXOEY83c5WcCnyoFv58MG4TGeHi/0
    #|coXKpdGlAqtQUqbp2sG7WCrXIGJJdBvUDIQDQQ0Isn6MK4nKBA10ucJmV+ok7DEP
    #|kyGk03KgAx+Vien9ELvo7P0AN75Nm1W9FiP6gfoNvUXDApKF7du1FTn4r3peLzzj
    #|50y5GcifWYfoRYi7OPhxI4cFYOWleFm1pIS4PwIDAQABAoIBAQCBleuCMkqaZnz/
    #|6GeZGtaX+kd0/ZINpnHG9RoMrosuPDDYoZZymxbE0sgsfdu9ENipCjGgtjyIloTI
    #|xvSYiQEIJ4l9XOK8WO3TPPc4uWSMU7jAXPRmSrN1ikBOaCslwp12KkOs/UP9w1nj
    #|/PKBYiabXyfQEdsjQEpN1/xMPoHgYa5bWHm5tw7aFn6bnUSm1ZPzMquvZEkdXoZx
    #|c5h5P20BvcVz+OJkCLH3SRR6AF7TZYmBEsBB0XvVysOkrIvdudccVqUDrpjzUBc3
    #|L8ktW3FzE+teP7vxi6x/nFuFh6kiCDyoLBhRlBJI/c/PzgTYwWhD/RRxkLuevzH7
    #|TU8JFQ9BAoGBAOIrQKwiAHNw4wnmiinGTu8IW2k32LgI900oYu3ty8jLGL6q1IhE
    #|qjVMjlbJhae58mAMx1Qr8IuHTPSmwedNjPCaVyvjs5QbrZyCVVjx2BAT+wd8pl10
    #|NBXSFQTMbg6rVggKI3tHSE1NSdO8kLjITUiAAjxnnJwIEgPK+ljgmGETAoGBAM3c
    #|ANd/1unn7oOtlfGAUHb642kNgXxH7U+gW3hytWMcYXTeqnZ56a3kNxTMjdVyThlO
    #|qGXmBR845q5j3VlFJc4EubpkXEGDTTPBSmv21YyU0zf5xlSp6fYe+Ru5+hqlRO4n
    #|rsluyMvztDXOiYO/VgVEUEnLGydBb1LwLB+MVR2lAoGAdH7s7/0PmGbUOzxJfF0O
    #|OWdnllnSwnCz2UVtN7rd1c5vL37UvGAKACwvwRpKQuuvobPTVFLRszz88aOXiynR
    #|5/jH3+6IiEh9c3lattbTgOyZx/B3zPlW/spYU0FtixbL2JZIUm6UGmUuGucs8FEU
    #|Jbzx6eVAsMojZVq++tqtAosCgYB0KWHcOIoYQUTozuneda5yBQ6P+AwKCjhSB0W2
    #|SNwryhcAMKl140NGWZHvTaH3QOHrC+SgY1Sekqgw3a9IsWkswKPhFsKsQSAuRTLu
    #|i0Fja5NocaxFl/+qXz3oNGB56qpjzManabkqxSD6f8o/KpeqryqzCUYQN69O2LG9
    #|N53L9QKBgQCZd0K6RFhhdJW+Eh7/aIk8m8Cho4Im5vFOFrn99e4HKYF5BJnoQp4p
    #|1QTLMs2C3hQXdJ49LTLp0xr77zPxNWUpoN4XBwqDWL0t0MYkRZFoCAG7Jy2Pgegv
    #|uOuIr6NHfdgGBgOTeucG+mPtADsLYurEQuUlfkl5hR7LgwF+3q8bHQ==
  guard (key.split("\n")
    |> @codec.base64_decode
    |> X690::from_iter
    |> Iter::collect)
    is [sequence]
  guard (sequence.content.iter()
    |> X690::from_iter
    |> Iter::map(fn {
      { tag: Integer, construction: Primitive, class: Universal, content } =>
        BigInt::from_octets(content)
      _ => panic()
    })
    |> Iter::collect)
    is [
      version,
      modulus,
      public_exponent,
      private_exponent,
      prime1,
      prime2,
      exponent1,
      exponent2,
      coefficient,
    ]
  assert_eq!(modulus.to_octets().length() * 8, 2048)
  inspect!(version, content="0")
  inspect!(
    modulus,
    content="22959099950256034890559187556292927784453557983859951626187028542267181746291385208056952622270636003785108992159340113537813968453561739504619062411001131648757071588488220532539782545200321908111599592636973146194058056564924259042296638315976224316360033845852318938823607436658351875086984433074463158236223344828240703648004620467488645622229309082546037826549150096614213390716798147672946512459617730148266423496997160777227482475009932013242738610000405747911162773880928277363924192388244705316312909258695267385559719781821111399096063487484121831441128099512811105145553708218511125708027791532622990325823",
  )
  inspect!(public_exponent, content="65537")
  inspect!(
    private_exponent,
    content="16358669625969388364581104141609389441427641540112063431899987561373091823318469317720180350787335685685177067883371926419606650760753757234961803841251641721018054151029890687512057093407910521097689161508401331075235897422153946629218362494511890545443766734301537836143051602334534677496098769959643127347674117653709560862767683574314126433987860854784002134418813937006574680192217906111795338155415665645853395279769810629758251647311243087303558250016935003936529217269852298186721078356080852876661955868636203495771866307776451235934278538058313992364138792492433515133366470972760378174187477470341640818497",
  )
  inspect!(
    prime1,
    content="158821241699809206379240050294221818859001463459205644463993958696866240205418400547814030766307080042644584970991123482171161583230900837955310531800680184932587150955639915773936331321003111715999458161371827010867661548650955374527536555325452958621842263169220276485047984007097022393251387885340530860307",
  )
  inspect!(
    prime2,
    content="144559378232613426908794876466633326578667289294577002125292145506864779092898829854943791512321347393777270116500424839118627337516633149490501210130514723656399948087736749754645662330251897374131452601460606973492794865585239015629328445163471765624481912162148836170882664246068101421643700397030187015589",
  )
  inspect!(
    exponent1,
    content="81806134795008306448937338873949767905508528037481192916536369741216620696924011585708198980396235729428464147973623378971449739309481965711848537803005340536938591250889369925092218691778721061339300077108026983320256510029606185481881250257431916691296966260331856406392797902369259882646247170994099520139",
  )
  inspect!(
    exponent2,
    content="81571484297729178029420683379046447811247005895948122672618960785348221548659408072778374870945507850058397945867253779932648085336567290252959782288425850977880075075645707656385724684301164484073962016183449143029693866429768284129395535813210085364892588822625785593411535567448074502552843193655085616117",
  )
  inspect!(
    coefficient,
    content="107767393137383684863285837530603262713505272336046170826402760673649439044164043252947591339783152332586428778090896779512434195821769203110139749156110797117634251017717788024337765459090675461882635600440921636154961089307247094064639739966306348042851661545457199055016518128892220899785968564685096557341",
  )
}
