# Contributing

Here is a step by step for contributing to the project:

- Fork the project
- Create a branch for your feature/fix
- Make it happen
- Create tests for it
- Make sure to run `mix format`
- Also, give `mix credo` a check, we enforce no warning on CI build
- Don't forget to add the changes you made to `CHANGELOG.md`
- Open a PR
- Wait for review!

## Releasing

Here is the step by step to release the project (team members only):

- Change the `version` key on `mix.exs` to the version you'll release
- Commit it to `master`
- Make sure CI passes and docs are good
- Prepare the version branch:
  - If you're releasing a major or minor, open a branch for it, with a naming like `1.0`
  - If you're releasing a patch with all the things on master, checkout the minor branch and
  `git rebase master` on it
  - If you're releasing a patch, but can't get everything of master, `git cherry-pick <sha>` of
  every commit you need, adapt if needed and push it
- Create a draft for your release on Github
  - From branch: `1.0`
  - Tag: `v1.0.0`
  - Release name: `1.0.0`
  - Description: exactly the same as changelog
- Run `mix hex.publish`
- Submit your release draft
- Update `README.md` version
