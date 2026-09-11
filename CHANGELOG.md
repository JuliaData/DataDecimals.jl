# Changelog

## 1.1.0

- `DataDecimals.RoundExact`, a rounding mode that requires the operation to
  be exact. `rescale`, `round(D, x, mode)`, `round(I, x, mode)`,
  `round(x, mode; digits)`, `divide`, `div`, `rem`, and `divrem` throw
  `InexactError` instead of dropping a digit. In the Parsers extension,
  `Parsers.parse(D, s; rounding=DataDecimals.RoundExact)` throws
  `InexactError`, `Parsers.tryparse` returns `nothing`, and
  `Parsers.parsenext` returns `Parsers.RC_INVALID` for a value the target
  scale cannot hold exactly. A CSV reader can request a decimal type and
  learn from the parse alone that a field needs rounding.

## 1.0.0

Initial public release of DataDecimals. See README.md for the API, representation,
limits, and validation commands.
