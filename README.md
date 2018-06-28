InternetTime

A package to add the ability to generate and parse Internet timestamp time zones to the Julia Dates package.

This adds the code `I` to the standard set of timestamp codes, which will parse a string conforming
to the timestamps listed in [RFC 822](https://www.w3.org/Protocols/rfc822/\#z28).
It also redefines `Dates.RFC1123Format` to use that timestamp.
