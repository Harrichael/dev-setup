## Comments

- Never just narrate the what or how of the code.
- When a comment is warranted, explain the why or motivation, succinctly.
- The bar for adding a comment: large ambiguity, or a design choice that
  would surprise the reader.
- No docstring boilerplate explaining function args, return values, etc.
- Do narrate "gotchas".
- For libraries, consider a file-level extended comment explaining how to
  use the module, with an example.
- In examples, illustrate the API generically. Concrete, evocative names
  are good (`users`, `posts`, `author`). Don't reference specific
  consumers, components, or features elsewhere in this project; the
  example should stand on its own.
- Project-internal references are fine (and often useful) in "why"
  comments; that's where the coupling actually lives. But use with discernment.

## Tests

- Refrain from very micro-unit tests; make each test really count. Test
  implementation behavior, not implementation details; do this by
  verifying input and output, and unit-under-test state (as opposed to steps).
- A bad test simply verifies that the unit under test does what it says it
  does. A good test verifies that the unit under test is obviously correct.
- Prefer fakes over mocks.
- Lean toward integrated tests written as unit tests.
- Sometimes tests will effectively test multiple files. Meaning that not every
  file of implementation needs its own test file.
- The implementation details that are put into tests are effectively ossified.
  So choose very wisely what details and levels of the stack should be
  ossified and hard to change.

## Architecture

- As we build, flag architecture issues and concerns early and not later.
- Pre-mature abstraction is very deadly to architecture just as pre-mature
  optimization is deadly to benchmarking.
- For architecture, think about the big O complexity of engineering effort
  of modification with respect to plausible app features.
- Pay special attention to the "telos" of a module, file, class, struct,
  function, etc. The Telos, the purpose that is, is the guiding north star
  of what belongs there and what doesn't. What should "know" about what?
- If a fundamental interface cannot be optimized without completely
  changing the interface or Telos, then its the wrong interface. We don't
  have to do the optimization right away, but it needs to be the right
  shape to do it under.
- Exposing implementation details is inevitable in many cases, like a
  field being a Vec or so forth. Coupling Telos or Knowledge is the thing
  to flag, not necessarily "implementation" details.
- Telos governs data shape; YAGNI governs API surface. Get the shape
  right now (where data lives, who owns what), but only implement the
  methods a real caller needs. The check: would a plausible future need
  force restructuring the data, or just adding a method? If restructure,
  the shape is wrong.
- Telos is hierarchial. A module has a Telos, and is composed of files which
  are composed of functions and so on. Each piece fulfills a Telos of the
  higher component.
- Telos need not be literally singular. If seemingly coupled Teloi
  can be disentangled hierarchically, as opposed to across its api surface,
  thus meaning its contained to behind the interface rather than leaking into
  the app as a whole, the unit is effectively singular. Per YAGNI, split later
  when a real caller forces the issue.
