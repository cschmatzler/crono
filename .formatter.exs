[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: [defparsec: 2],
  plugins: [Styler],
  line_length: 100
]
