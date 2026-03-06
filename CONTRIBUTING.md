# Committing
Please follow [Conventional Commits](https://www.conventionalcommits.org/) when contributing to this project. This project uses commit messages
to automatically make release notes, so it is important to adhere to the conventions.
Furthermore, it'll be appreciated if you write your commits in *Imperative Mood* (e.g. "add xyz", not "added xyz").

Commits must have one of the following types:

- `feat` - new feature
- `fix` - bug fix
- `docs` - documentation only
- `style` - formatting, no logic change
- `refactor` - code restructure, no feature/fix
- `test` - adding or updating tests
- `chore` - build process, tooling, dependencies
- `perf` - performance improvement
- `ci` - CI/CD changes
- `revert` - reverts a previous commit

Commits must be accompanied by scopes. The list of applicable scopes is given below and will be 
added onto as the project grows:

**Quickshell Related**
- `bar` - entire bar module
- `sidebar` - control center with notifications + media player
- `calendar` - calendar + clock + todo
- `services` - any service singleton

**Misc**
- `hypr` - hyprland configuration
- `dev` - developers QoL
