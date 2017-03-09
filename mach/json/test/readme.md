# JSONTestSuite

The correctness of the parsing behavior of `mach.text.json` is validated
using the inputs graciously provided by Nicolas Seriot here:
https://github.com/nst/JSONTestSuite

Below is every input where the parser deviates from the expected behavior and
an explanation as to why.

## REJECTED VALID: y_object_duplicated_key.json

Debatable whether duplicate identical keys should be considered valid.

See: https://github.com/nst/JSONTestSuite/issues/56

## REJECTED VALID: y_object_duplicated_key_and_value.json

Debatable whether duplicate identical keys should be considered valid.

See: https://github.com/nst/JSONTestSuite/issues/56

## REJECTED VALID: y_string_utf16BE_no_BOM.json

Debatable whether UTF-16 should be considered valid in this case.

See: https://github.com/nst/JSONTestSuite/issues/20

## REJECTED VALID: y_string_utf16LE_no_BOM.json

Debatable whether UTF-16 should be considered valid in this case.

See: https://github.com/nst/JSONTestSuite/issues/20
