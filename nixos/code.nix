{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Haskell
    cabal-install
    cabal2nix
    ghc
    # stack
    haskellPackages.hpack
    haskellPackages.hasktags
    haskellPackages.hoogle
    # (all-hies.selection { selector = p: { inherit (p) ghc864 ghc865; }; })

    # Scala
    sbt
    scala

    # Node
    nodePackages.npm
    nodejs

    # Rust
    cargo
    carnix
    # rls
    rustc
    rustfmt

    # Clojure
    boot
    leiningen

    # Ruby
    ruby

    # purescript
    purescript
    spago

    # dhall
    haskellPackages.dhall
    haskellPackages.dhall-json
  ];
}
