# Unit tests

- make sure each test follows the arrange/act/assert structure
- use Swift Testing
- make sure to avoid reliance on current user locale or timezone to avoid making tests flaky
- always write both blue-sky (happy path) and negative (error/edge case) scenarios

# Commits

- follow Conventional Commits (https://www.conventionalcommits.org/en/v1.0.0-beta.2/)
- use `chore` for maintenance that does not affect production code, tests, or docs (e.g. .gitignore changes)

# General

- do not leak domain knowledge into this library (e.g. no personal finance terminology in names, comments, or examples)
