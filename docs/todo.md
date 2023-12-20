# Now

- Split fs-requiring code into separate library (e.g. string templates vs file
  templates)

- Consider using lpeg

- failing "check" call doesn't cause toku template to exit with a
  failed status

- for simplicity, chunks in toku templates should not special case returning
  booleans. instead, anything can be returned, and the first value returned is
  converted to a string with tostring(...)

- toku template excludes functionality is a bit confusing in that it excludes
  the file from being templated, but, when invoked via the command line, still
  copies it. First, this functionality should be the same whether invoked from
  the command line or from a library call, and second, instead, there should be
  a way to differentiate between files that should be totally excluded (neither
  templated nor copied) and files that should not be templated but still copied.

- template: allow `<%- ... %>` or similar to indicate that prefix should not be
  interpreted
- stack.pop should accept "n"
