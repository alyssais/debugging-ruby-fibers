You may have encountered a bug in the Ruby interpreter
======================================================

A high-level talk about tracking down a bug in Ruby itself.

Using the presentation
----------------------

Prebuilt slides are available at
https://alyssais.github.io/debugging-ruby-fibers.

The slides (including presenter notes) are written in Markdown, and are
designed to be converted to a [revealjs][] presentation using
[pandoc][]. A [Nix][] expression is provided to provide a reproducible
way to generate the presentation.

Generate the slides with `nix build`, and then open `result/index.html`
in a web browser.

License
-------

The slides and README are licensed under a [Creative Commons
Attribution-ShareAlike 4.0 International License][CC-BY-SA-4.0].

The Nix expression for generating the presentation is subject to the
terms of the [Mozilla Public License, v. 2.0][MPL-2.0].

[revealjs]: https://revealjs.com/
[pandoc]: https://pandoc.org/
[Nix]: https://nixos.org/nix/
[CC-BY-SA-4.0]: https://creativecommons.org/licenses/by-sa/4.0/
[MPL-2.0]: https://www.mozilla.org/en-US/MPL/2.0/
