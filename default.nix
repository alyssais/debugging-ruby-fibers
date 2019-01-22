# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

{ pkgs ? import (builtins.fetchTarball {
    url = https://github.com/NixOS/nixpkgs/archive/a5de41088031e6d3d4f799ef3964317a74e72169.tar.gz;
    sha256 = "0ycsai65dbcwmns36a0pkxpsgpl86q273c27ag80nijfb1w88201";
  }) {}

, revealjs ? pkgs.fetchFromGitHub {
    owner = "hakimel";
    repo = "reveal.js";
    rev = "3.7.0";
    sha256 = "1raqacq2c6rcbqkli1jygw68nqs090zm59zrbdvflk6y1mzk93nd";
  }

, controls ? false
, progress ? false
, theme ? "white"
, transition ? "none"
}:

pkgs.runCommand "ruby-talk" {} ''
  mkdir $out
  ln -s ${revealjs} $out/reveal.js
  ${pkgs.pandoc}/bin/pandoc -s -t revealjs -o $out/index.html \
      -V controls=${builtins.toJSON controls} \
      -V progress=${builtins.toJSON progress} \
      -V theme=${theme} \
      -V transition=${transition} \
      ${./slides.md}
''
