# Base 64 encoding and decoding

BASE64_STANDARD_ALPHABET := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".utf8()
BASE64_STANDARD_DECODER : {Byte:Byte} = {b:Byte(i-1) for i,b in BASE64_STANDARD_ALPHABET}

BASE64_URL_ALPHABET := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".utf8()
BASE64_URL_DECODER : {Byte:Byte} = {b:Byte(i-1) for i,b in BASE64_STANDARD_ALPHABET}

_EQUAL_BYTE := Byte(0x3D)


lang Base64
    func encode_text(text:Text, alphabet:[Byte]=BASE64_STANDARD_ALPHABET -> Base64)
        return Base64.encode_bytes(text.utf8(), alphabet=alphabet)

    func encode_bytes(bytes:[Byte], alphabet:[Byte]=BASE64_STANDARD_ALPHABET -> Base64)
        output : &[Byte]
        src := Int64(1)

        while src + 2 <= Int64(bytes.length)
            b1 := bytes[src]!
            b2 := bytes[src + 1]!
            b3 := bytes[src + 2]!
            src += 3

            output.insert(alphabet[1 + (b1 >> 2)]!)
            output.insert(alphabet[1 + (((b1 and 0b11) << 4) or (b2 >> 4))]!)
            output.insert(alphabet[1 + (((b2 and 0b1111) << 2) or (b3 >> 6))]!)
            output.insert(alphabet[1 + (b3 and 0b111111)]!)

        if src + 1 == bytes.length
            b1 := bytes[src]!
            b2 := bytes[src + 1]!
            output.insert(alphabet[1 + (b1 >> 2)]!)
            output.insert(alphabet[1 + (((b1 and 0b11) << 4) or (b2 >> 4))]!)
            output.insert(alphabet[1 + ((b2 and 0b1111) << 2)]!)
            output.insert(_EQUAL_BYTE)
        else if src == bytes.length
            b1 := bytes[src]!
            output.insert(alphabet[1 + (b1 >> 2)]!)
            output.insert(alphabet[1 + ((b1 and 0b11) << 4)]!)
            output.insert(_EQUAL_BYTE)
            output.insert(_EQUAL_BYTE)

        return Base64.from_text(Text.from_utf8(output[])!)

    func decode_text(b64:Base64 -> Text?)
        bytes := b64.decode_bytes() or return none
        return Text.from_utf8(bytes)

    func decode_bytes(b64:Base64, decoder:{Byte:Byte}=BASE64_STANDARD_DECODER -> [Byte]?)
        text := b64.text
        bytes := text.utf8()
        if bytes.length mod 4 != 0
            return none
        output : &[Byte]
        src := Int64(1)
        while src + 3 <= Int64(bytes.length)
            is_last_chunk := src + 3 >= bytes.length

            b1 := bytes[src]!
            b2 := bytes[src+1]!
            b3 := bytes[src+2]!
            b4 := bytes[src+3]!

            src += 4

            if is_last_chunk and b4 == _EQUAL_BYTE
                x1 := decoder[b1] or return none
                x2 := decoder[b2] or return none
                output.insert((x1 << 2) or (x2 >> 4))
                if b3 != _EQUAL_BYTE and b4 == _EQUAL_BYTE
                    x3 := decoder[b3] or return none
                    output.insert((x2 << 4) or (x3 >> 2))
            else
                x1 := decoder[b1] or return none
                x2 := decoder[b2] or return none
                x3 := decoder[b3] or return none
                x4 := decoder[b4] or return none
                output.insert((x1 << 2) or (x2 >> 4))
                output.insert(((x2 and 0b1111) << 4) or (x3 >> 2))
                output.insert(((x3 and 0b11) << 6) or x4)

        return output[]


func _test()
    for test in ["", "A", "AB", "ABC", "ABCD", "ABCDE", "ABCDEF", "ABCDEFG", "ABCDEFGH", "ABCDEFGHI"]
        b64 := Base64.encode_text(test)
        assert b64.decode_text() == test

    for test in [[Byte(0xFF)], [Byte(0xFF), 0xFE]]
        b64 := Base64.encode_bytes(test)
        assert b64.decode_bytes() == test

        b64url := Base64.encode_bytes(test, alphabet=BASE64_URL_ALPHABET)
        assert b64url.decode_bytes(decoder=BASE64_URL_DECODER) == test

    all_bytes := [Byte(i) for i in (0).to(255)]
    for len in 10
        bytes := [all_bytes.random() for _ in len]
        assert Base64.encode_bytes(bytes).decode_bytes() == bytes

func main(input|i=(/dev/stdin), output|o=(/dev/stdout), url|u=no, decode|d=no, test|t=no)
    if test
        _test()
    else if decode
        text := input.read()!.trim(" \r\n")
        b := Base64.from_text(text)
        decoder := if url then BASE64_URL_DECODER else BASE64_STANDARD_DECODER
        (/dev/stdout).write_bytes(b.decode_bytes(decoder=decoder) or exit("Invalid Base64 encoding!"))
    else
        bytes := input.read_bytes()!
        alphabet := if url then BASE64_URL_ALPHABET else BASE64_STANDARD_ALPHABET
        say(Base64.encode_bytes(bytes, alphabet=alphabet).text)
