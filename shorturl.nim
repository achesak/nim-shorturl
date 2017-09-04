# Nim module for generating URL identifiers for Tiny URL and bit.ly-like URLs.
# Based on the python-short_url module by Alireza Savand at
# https://github.com/Alir3z4/python-short_url

# Written by Adam Chesak.
# Released under the MIT open source license.


## shorturl is a Nim module for generating URL identifiers for Tiny URL and bit.ly-like URLs.
## It is based on the python-short_url module by Alireza Savand, at
## https://github.com/Alir3z4/python-short_url. See the README of that repository
## for more information on how the module works.
##
## IMPORTANT NOTE: shorturl will *not* generate the same values as python-short_url.
## Be careful if using values from one library with the other.
##
## Examples:
##
## .. code-block:: nimrod
##
##    # Generate a URL from an integer.
##    var url : string = encodeURLSimple(100)
##    echo(url) # outputs "6d7gw"
##
##    # Get the key back from the URL.
##    var key : int = decodeURLSimple(url)
##    echo(key) # outputs 100


import algorithm
import math


const DEFAULT_ALPHABET* : string = "mn6j2c4rv8bpygw95z7hsdaetxuk3fq"
const DEFAULT_BLOCK_SIZE* : int  = 24
const MIN_LENGTH* : int = 5


type
    URLEncoder* = ref  object
        alphabet* : string
        block_size* : int
        mask* : int
        mapping* : seq[int]

    URLEncoderError* = object of Exception


proc createURLEncoder*(alphabet : string = DEFAULT_ALPHABET, block_size = DEFAULT_BLOCK_SIZE): URLEncoder =
    ## Creates a new ``URLEncoder`` object.

    if len(alphabet) < 2:
        raise newException(URLEncoderError, "Alphabet must contain at least two characters.")

    var encoder : URLEncoder = URLEncoder(alphabet: alphabet, block_size: block_size, mask: (1 shl block_size) - 1)
    var mapping : seq[int] = newSeq[int](block_size)
    for i in 0..(block_size - 1):
        mapping[i] = i
    encoder.mapping = mapping

    return encoder


proc encodeInternal(encoder : URLEncoder, n : int): int =
    ## Internal proc.

    var r : int = 0
    var rmap : seq[int] = reversed(encoder.mapping)

    for i in 0..high(rmap):
        if (n and (1 shl i)) != 0:
            r = r or (1 shl rmap[i])

    return r


proc decodeInternal(encoder : URLEncoder, n : int): int =
    ## Internal proc.

    var r : int = 0
    var rmap : seq[int] = reversed(encoder.mapping)

    for i in 0..high(rmap):
        if (n and (1 shl rmap[i])) != 0:
            r = r or (1 shl i)

    return r


proc enbaseInternal(encoder : URLEncoder, x : int): string =
    ## Internal proc.

    var n : int = len(encoder.alphabet)
    if x < n:
        return "" & encoder.alphabet[x]

    return enbaseInternal(encoder, int(x / n)) & encoder.alphabet[int(x mod n)]


proc findIndex(s : string, v : string): int =
    ## Internal proc.

    for i in 0..high(s):
        if ("" & s[i]) == v:
            return i
    return -1


proc encode*(encoder : URLEncoder, n : int): int =
    ##

    return (n and not encoder.mask) or encodeInternal(encoder, n and encoder.mask)


proc decode*(encoder : URLEncoder, n : int): int =
    ##

    return (n and not encoder.mask) or decodeInternal(encoder, n and encoder.mask)


proc enbase*(encoder : URLEncoder, x : int, min_length : int = MIN_LENGTH): string =
    ##

    var r : string = enbaseInternal(encoder, x)
    if min_length - len(r) > 0:
        for i in 0..(min_length - len(r)):
            r &= "" & encoder.alphabet[0]

    return r


proc debase*(encoder : URLEncoder, x : string): int =
    ##

    var n : int = len(encoder.alphabet)
    var r : int = 0
    var xrev : seq[char] = reversed(x)

    for i in 0..high(xrev):
        r += findIndex(encoder.alphabet, "" & xrev[i]) * int(math.pow(float(n), float(i)))

    return r


proc encodeURL*(encoder : URLEncoder, n : int, min_length : int = MIN_LENGTH): string =
    ##

    return encoder.enbase(encoder.encode(n), min_length)


proc decodeURL*(encoder : URLEncoder, n : string): int =
    ##

    return encoder.decode(encoder.debase(n))


proc encodeURLSimple*(n : int, min_length : int = MIN_LENGTH): string =
   ## Encodes a URL from the given integer.

   return createURLEncoder().encodeURL(n, min_length)


proc decodeURLSimple*(n : string): int =
    ## Decodes an int from the given URL.

    return createURLEncoder().decodeURL(n)
