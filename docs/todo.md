# Now

- Leverage string indices instead of repeated subs in compile and render

- Split fs-requiring code into separate library (e.g. string templates vs file
  templates)

- toku template excludes functionality is a bit confusing in that it excludes
  the file from being templated, but, when invoked via the command line, still
  copies it. First, this functionality should be the same whether invoked from
  the command line or from a library call, and second, instead, there should be
  a way to differentiate between files that should be totally excluded (neither
  templated nor copied) and files that should not be templated but still copied.

# Consider

- Lpeg?

- template: allow `<%- ... %>` or similar to indicate that prefix should not be
  interpreted

- stack.pop should accept "n"

- filter for render/copy
- auto-indent lines based on parent indent
