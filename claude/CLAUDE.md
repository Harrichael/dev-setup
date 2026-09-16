## Planning and User Interaction

- Say the controversial or opinionated piece up-front. Don't bury it. The
  structure of the plan "onions" out from there.
- Be careful of extreme Claudish terse-ness and extreme verbosity. Terseness and
  verbosity are orthogonal to the axis of clarity. Instead, take this advice
  from G.K. Chesterton:

  Long words go rattling by us like long railway trains. We know they are
  carrying thousands who are too tired or too indolent to walk and think for
  themselves. It is a good exercise to try for once in a way to express any
  opinion one holds in words of one syllable. If you say "The social utility
  of the indeterminate sentence is recognised by all criminologists as a part
  of our sociological evolution towards a more humane and scientific view of
  punishment," you can go on talking like that for hours with hardly a
  movement of the grey matter inside your skull. But if you begin "I wish
  Jones to go to jail and Brown to say when Jones shall come out," you will
  discover, with a thrill of horror, that you are obliged to think. The long
  words are not the hard words, it is the short words that are hard. There is
  much more metaphysical subtlety in the word "damn" than in the word
  "degeneration."

## Architecture

- For architecture, think about the big O complexity of engineering effort
  of modification with respect to plausible app features. From this flows out
  the following guidance.
- Pay special attention to the "telos" of a module, file, class, struct,
  function, etc. The Telos, the purpose that is, is the guiding north star
  of what belongs there and what doesn't. What should "know" about what?
- [IMPORTANT] Telos governs shape; YAGNI governs surface. Get the shape
  right now (where data lives, who owns what, telos and api alignment),
  but only implement the methods a real caller needs.
    - The check: would a plausible future need force restructuring the data,
      or just adding a method? If restructure, the shape is wrong.
- [IMPORTANT] Telos is hierarchical because shape is hierarchical.
  A module has a Telos, and is composed of files which are further composed of
  classes and functions and so on. Each sub-component fulfills a portion of the
  higher Telos of the higher component, while carrying its own Telos. How a
  component is sub-composed is surface.
  [KEY INSIGHT] Subcomposition of Telos is surface, and thus governed by
  YAGNI. All further guidance is to nuance this delicate, beautiful interplay of
  Telos and YAGNI, shape and surface.

### Finer Points on Telos and YAGNI, Shape and Surface

- Since Telos is hierarchical (shape/containment), common wisdom that "my
  resolver shouldn't know table names" is completely wrong, as it MUST know. The
  sub-composition though is governed by YAGNI (surface/distribution).
- Telos is about knowledge and purpose not implementation details. If a new
  module's Telos is "let users order products," database details are in scope.
  Hierarchy runs both ways: an existing component that owns user and product
  data becomes a sub-component of the new one. Leave it alone if its Telos
  already fits; change it only if it now holds too much or too little. Here
  subcomposition is forced, not deferred: the caller is real today.
- Telos is about knowledge and purpose not implementation details. Exposing and
  coupling implementation details is often unavoidable (like a field being a Vec
  or so forth). The issue is the "wrong" implementation details leaking, but
  knowledge is the thing that delineates right from wrong here.
- If a fundamental interface cannot be optimized without completely
  changing the interface or Telos, then its the wrong interface. We don't
  have to do the optimization right away, but it needs to be the right
  shape to do it under.
- Pre-mature abstraction is very deadly to architecture just as pre-mature
  optimization is deadly to benchmarking.
    - However, Knuth's pre-mature optimization quote is often misused, and
      likewise our pre-mature abstraction one should not be misused. You can
      know apriori or very early the general shape of optimization AND
      abstraction, so do so. The frontier of abstraction and optimization should
      be data and utility driven.

## Tests

- Ideally, good tests are:
    - fast, with low setup
    - refactorable: not bound to arbitrary implementation details
    - readable and obviously correct
    - independent and deterministic
- Take a Classicist/Chicago approach to testing, minus the TDD aspects of tests
  before implementation. The following details build on that position.
- Strongly prefer simulated fixtures and fakes over mocks.
- The implementation details that are put into tests are ossified.
  So choose very wisely what details and levels of the stack should be
  ossified and hard to change.
- Test implementation behavior, not implementation details; do this by
  verifying input and output, and unit-under-test final state (as opposed to
  steps).
- A good test verifies that the unit under test is obviously correct when
  reading the test file alone. Ideally, it operates more at the story/behavior
  level and not mechanism/detail level.
- Refrain from very micro-unit tests; make each test really count.
- Its okay to do "integrated" tests in "unit" tests. Scare quotes because the
  normal terminology here is subversive to our rules here. Units proper are
  composable, thus a "unit" test may test a set of composed (or "integrated")
  units. This is in accordance with the Chicago approach to testing.
- Sometimes tests will effectively test multiple files. Meaning that not every
  file of implementation needs its own test file.
- Mocks should be tactical and rare, and the interface that is mocked is ideally
  simple, low surface area, not stateful, and extremely stable.

## Comments

- The bar for adding a comment: large ambiguity, or a design choice that
  would surprise the reader. This is important and all further guidance should
  be read in light of this.
- When a comment is warranted, explain the why or motivation, succinctly. Never
  just narrate the what or how of the code.
- For tests, don't over-narrate the steps. However, a good multiline header
  comment to introduce the test is fantastic.
- No docstring boilerplate explaining function args, return values, etc. That is
  what or how.
- Do narrate footguns, but don't be pedantic.
- Be careful not to follow the apparent comment standards of a file by a matter
  of precedent. These instructions supersede precedent.
- Comments are not the place to capture historic back and forth. Sometimes the
  right call is not add and add more to a comment, but to go back and reframe
  and even delete comments. Comments about history should be very rare.
- For published or broadly shared libraries, consider a file-level extended
  comment explaining how to use the module, with an example.
    - In examples, illustrate the API generically. Concrete, evocative names
      are good (`users`, `posts`, `author`). Don't reference specific
      consumers, components, or features elsewhere in this project; the
      example should stand on its own.

## Agentic Scope

- Do not use git tools, like add commit push merge etc, without explicit
  permission.
- If asked to resolve git merge, investigate the intention of both branches and
  resolve the files, but do not git add or merge.
