{ config, lib, pkgs, ... }:

let
  cfg = config.services.sotavpn;
  daemonDir = "${cfg.package}/libexec/sota-daemon";
in
{
  options.services.sotavpn = {
    enable = lib.mkEnableOption "the Sota Connect VPN daemon (sotad)";

    package = lib.mkOption {
      type = lib.types.package;
      description = "The sotavpn package providing sotad, sing-box and the GUI.";
    };

    installGui = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Add the Sota Connect GUI and its .desktop entry to systemPackages.";
    };

    fhsCompat = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Bind-mount the daemon directory onto /usr/libexec/sota-daemon inside the
        service's own mount namespace, so the vendor's FHS layout is visible to
        the daemon without touching the real filesystem. sotad appears to locate
        sing-box relative to itself, so this is belt-and-braces — but it costs
        nothing and survives an upstream change of heart.
      '';
    };

    splitTunnelAppDiscovery = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Make the per-app split-tunnel picker work. sotad scans the hardcoded FHS
        paths /usr/share/applications and /usr/share/icons, which do not exist on
        NixOS; this maps the system profile's equivalents into the service's mount
        namespace so the picker actually lists your installed apps.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = lib.optional cfg.installGui cfg.package;

    boot.kernelModules = [ "tun" ];

    # sing-box does not touch the default route: it brings up tun0 and installs
    # policy rules (priorities 9000-9010) diverting traffic into table 2022.
    # NixOS's firewall defaults to strict reverse-path filtering, which silently
    # drops the return packets of exactly that setup — the tunnel comes up and
    # then nothing flows. Loose mode is what the vendor's own Arch install runs
    # with (all.rp_filter=0, tun0=2). mkDefault so an explicit setting wins.
    networking.firewall.checkReversePath = lib.mkDefault "loose";

    # The tunnel interface must be trusted, otherwise the firewall drops the
    # traffic sing-box writes back into tun0 and the VPN comes up dead: routes
    # and rules all correct, zero bytes flowing. Confirmed on a NixOS VM —
    # disabling the firewall wholesale fixed it, so this is the targeted form.
    networking.firewall.trustedInterfaces = [ "tun0" ];

    # Empty mount points for the BindPaths below. systemd refuses to set up the
    # namespace if the destination is missing, and NixOS ships no /usr/libexec.
    systemd.tmpfiles.rules =
      lib.optionals cfg.fhsCompat [
        "d /usr/libexec 0755 root root -"
        "d /usr/libexec/sota-daemon 0755 root root -"
      ]
      ++ lib.optionals cfg.splitTunnelAppDiscovery [
        "d /usr/share 0755 root root -"
        "d /usr/share/applications 0755 root root -"
        "d /usr/share/icons 0755 root root -"
      ];

    systemd.services.sotad = {
      description = "Sota Connect Daemon (sotad)";
      documentation = [ "https://sotavpn.com/" ];
      after = [ "network.target" "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      # sotad shells out to `ip route`/`ip link`/`ip addr`; a systemd unit's
      # default PATH does not include iproute2.
      path = [ pkgs.iproute2 ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${daemonDir}/sotad";
        WorkingDirectory = daemonDir;
        Restart = "on-failure";
        RestartSec = 5;
        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = "sotad";

        NoNewPrivileges = true;
        PrivateTmp = false; # sing-box configs land in /tmp and are read back
        ProtectSystem = false;
        ProtectHome = false;
        StateDirectory = "sota-connect";
        StateDirectoryMode = "0750";
        ReadWritePaths = [ "/tmp" "/var/lib/sota-connect" ];

        # CAP_NET_ADMIN/RAW: TUN device, routes. CAP_DAC_READ_SEARCH: read
        # rule_sets out of the user's home. CAP_SYS_PTRACE: readlink
        # /proc/PID/exe for the split-tunnel app picker.
        AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_RAW" "CAP_DAC_READ_SEARCH" "CAP_SYS_PTRACE" ];
        CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_RAW" "CAP_DAC_READ_SEARCH" "CAP_SYS_PTRACE" ];

        LimitNOFILE = 65536;

        BindReadOnlyPaths =
          lib.optionals cfg.fhsCompat [
            "${daemonDir}:/usr/libexec/sota-daemon"
          ]
          ++ lib.optionals cfg.splitTunnelAppDiscovery [
            # `-` marks the source optional: a missing path must not stop the daemon.
            "-/run/current-system/sw/share/applications:/usr/share/applications"
            "-/run/current-system/sw/share/icons:/usr/share/icons"
          ];
      };
    };
  };
}
