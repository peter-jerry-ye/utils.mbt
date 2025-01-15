test "base64 encode" {
  fn test_str!(input : String, expected : String) {
    [@encoding.encode(UTF8, input)].iter()
    |> base64_encode
    |> String::from_iter
    |> inspect!(content=expected)
  }

  test_str!("light w", "bGlnaHQgdw==")
  test_str!("light wo", "bGlnaHQgd28=")
  test_str!("light wor", "bGlnaHQgd29y")
  test_str!("light work", "bGlnaHQgd29yaw==")
  test_str!("light work.", "bGlnaHQgd29yay4=")
  test_str!("a Ā 𐀀 文 🦄", "YSDEgCDwkICAIOaWhyDwn6aE")
}

test "base64 decode" {
  fn test_str!(expected : String, input : String) {
    let buffer = @buffer.new()
    [input].iter()
    |> base64_decode
    |> Iter::each(fn(b) { buffer.write_byte(b) })
    @encoding.decode_strict(UTF8, buffer.contents()).to_string!()
    |> inspect!(content=expected)
  }

  test_str!("light w", "bGlnaHQgdw==")
  test_str!("light wo", "bGlnaHQgd28=")
  test_str!("light wor", "bGlnaHQgd29y")
  test_str!("light work", "bGlnaHQgd29yaw==")
  test_str!("light work.", "bGlnaHQgd29yay4=")
  test_str!("a Ā 𐀀 文 🦄", "YSDEgCDwkICAIOaWhyDwn6aE")
}
