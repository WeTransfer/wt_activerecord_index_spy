## Sorbet

Up to you! First things first, you'll probably want to typecheck your project:

    srb tc

Other than that, it's up to you!
We recommend skimming these docs to get a feel for how to use Sorbet:

- Gradual Type Checking (https://sorbet.org/docs/gradual)
- Enabling Static Checks (https://sorbet.org/docs/static)
- RBI Files (https://sorbet.org/docs/rbi)

If instead you want to explore your files locally, here are some things to try:

- Upgrade a file marked # typed: false to # typed: true.
  Then, run srb tc and try to fix any errors.
- Add signatures to your methods with `sig`.
  For how, read: https://sorbet.org/docs/sigs
- Check whether things that show up in the TODO RBI file actually exist in your project.
  It's possible some of these constants are typos.
- Upgrade a file marked # typed: ignore to # typed: false.
  Then, run srb rbi hidden-definitions && srb tc and try to fix any errors.
