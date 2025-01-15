///|
pub(open) trait ByteSequence {
  iter(Self) -> Iter[Byte]
}

///|
fn &ByteSequence::empty() -> Iter[Byte] {
  Iter::empty()
}

///|
pub impl ByteSequence for Bytes with iter(self) { self.iter() }

///|
pub impl ByteSequence for @buffer.T with iter(self) { self.iter() }

///|
pub impl ByteSequence for Array[Byte] with iter(self) { self.iter() }

///|
pub impl ByteSequence for FixedArray[Byte] with iter(self) { self.iter() }

///|
pub impl ByteSequence for Iter[Byte] with iter(self) { self }

///|
pub(open) trait CharSequence {
  iter(Self) -> Iter[Char]
}

///|
pub impl CharSequence for String with iter(self) { self.iter() }

///|
pub impl CharSequence for Iter[Char] with iter(self) { self }

///|
fn &CharSequence::empty() -> Iter[Char] {
  Iter::empty()
}
