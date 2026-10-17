# nixos/work/falcon-sensor.nix — CrowdStrike Falcon sensor (user-mode/eBPF).
#
# The sensor .deb is proprietary and fetched with requireFile, so it must be in
# the local store before building. Download it from the Falcon console (Host
# setup and management > Sensor downloads), then run:
#   nix-store --add-fixed sha256 falcon-sensor_8.10.0-19403_amd64.deb
# Sensor updates must be disabled for this host in the Falcon console; upgrade
# by bumping version/name/sha256 below.
#
# Unfree is already allowed globally (../common.nix), which covers both the
# package and its .deb source.
{ inputs, pkgs, ... }:

{
  imports = [ inputs.falcon-sensor.nixosModules.default ];

  services.falcon-sensor = {
    enable = true;
    package = inputs.falcon-sensor.lib.mkFalconSensor pkgs {
      version = "8.10.0-19403";
      src = pkgs.requireFile {
        name = "falcon-sensor_8.10.0-19403_amd64.deb";
        sha256 = "f35e31f05a475c766b19e762dc78846ac2900633cd931030e041eb931194b160";
        message = ''
          Download the Debian/Ubuntu sensor package from the Falcon console
          (Host setup and management > Sensor downloads), then run:
            nix-store --add-fixed sha256 falcon-sensor_8.10.0-19403_amd64.deb
        '';
      };
    };
    # Root-only (0600) file holding CID-CHECKSUM; kept out of the Nix store and
    # passed to the service via systemd LoadCredential=.
    cidFile = "/var/lib/falcon/cid";
    tags = [ "nixos" ];
  };
}
