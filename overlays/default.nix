# overlays/default.nix — nixpkgs overlays applied to every host.
#
# This is a list of standard `final: prev:` overlays, consumed by flake.nix
# (Linux hosts, via `import nixpkgs { overlays = ...; }`) and by
# darwin/common.nix (macOS hosts, via `nixpkgs.overlays`).
#
# Everything here is a workaround for a bug in nixpkgs-unstable. Each entry
# says what broke and when it can go — recheck them after `nix flake update`
# and delete the ones upstream has fixed.
[
  # curl-impersonate 2.1.0 sets its macOS dylib install_name to the relative
  # `@rpath/libcurl-impersonate.4.dylib` rather than the absolute store path.
  # Nothing in the build adds a matching -rpath, so consumers that link it —
  # python3Packages.curl-cffi, and through it yt-dlp — fail to load with
  # "Library not loaded: @rpath/libcurl-impersonate.4.dylib ... no LC_RPATH's
  # found". Version 1.5.6 used the absolute store path and worked; the 2.x
  # bump regressed it.
  #
  # Rewriting the id back to the store path is the convention for darwin
  # dylibs in nixpkgs, and fixes every consumer at once rather than patching
  # each one to carry an rpath.
  (
    final: prev:
    prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
      curl-impersonate = prev.curl-impersonate.overrideAttrs (old: {
        postFixup = (old.postFixup or "") + ''
          for f in "$out"/lib/libcurl-impersonate*.dylib; do
            # lib/ also holds version symlinks (libcurl-impersonate.4.dylib ->
            # libcurl-impersonate.4.8.0.dylib); only the real Mach-O has an id.
            [ -L "$f" ] || install_name_tool -id "$f" "$f"
          done
        '';
      });
    }
  )

  # curl-cffi's test suite has four darwin-only failures that are test bugs,
  # not packaging bugs (367 other tests pass):
  #
  #   * test_verify (x3, in test_async_session/test_curl/test_requests) asserts
  #     on the string "SSL certificate problem", but the LibreSSL-backed curl
  #     on darwin words the same error as "no alternative certificate subject
  #     name matches target ipv4 address '127.0.0.1'".
  #   * test_delete_cookies leaves a cookie set on the 127.0.0.1 test server.
  #
  # These only became visible once the install_name fix above let the build get
  # past pythonImportsCheck. Upstream already disables a batch of similar
  # network/TLS-sensitive tests in this derivation; this extends that list.
  (
    final: prev:
    prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (
          pyfinal: pyprev: {
            curl-cffi = pyprev.curl-cffi.overrideAttrs (old: {
              disabledTests = (old.disabledTests or [ ]) ++ [
                "test_verify"
                "test_delete_cookies"
              ];
            });
          }
        )
      ];
    }
  )

  # semgrep-core 1.180.0 fails in postFixup with patchelf's
  # `shiftFile: Assertion 'splitIndex == -1' failed` (patchelf 0.19.2 and
  # patchelfUnstable alike). The upstream wheel binary has already been through
  # patchelf once, and setting interpreter and rpath together trips over the
  # earlier rewrite.
  #
  # The rpath change isn't needed: the binary's RUNPATH already includes
  # $ORIGIN/libs, where the bundled libs live, and the Nix loader finds glibc
  # in its own directory. Setting just the interpreter succeeds and gives a
  # working binary. Drop this once nixpkgs' semgrep-core builds again.
  (
    final: prev:
    prev.lib.optionalAttrs prev.stdenv.hostPlatform.isLinux {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (
          pyfinal: pyprev: {
            semgrep = pyprev.semgrep.override {
              semgrep-core = pyprev.semgrep.passthru.semgrep-core.overrideAttrs {
                postFixup = ''
                  patchelf \
                    --set-interpreter "$(cat ${final.stdenv.cc}/nix-support/dynamic-linker)" \
                    $out/bin/semgrep-core
                '';
              };
            };
          }
        )
      ];
    }
  )
]
