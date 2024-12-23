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
    @encoding.decode_strict(
      UTF8,
      [input].iter() |> base64_decode |> Bytes::from_iter,
    ).to_string!()
    |> inspect!(content=expected)
  }

  test_str!("light w", "bGlnaHQgdw==")
  test_str!("light wo", "bGlnaHQgd28=")
  test_str!("light wor", "bGlnaHQgd29y")
  test_str!("light work", "bGlnaHQgd29yaw==")
  test_str!("light work.", "bGlnaHQgd29yay4=")
  test_str!("a Ā 𐀀 文 🦄", "YSDEgCDwkICAIOaWhyDwn6aE")
}
