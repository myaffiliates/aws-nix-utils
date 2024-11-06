{ pkgs, lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf mdDoc;
  cfg = config.services.efs-utils;
in
{
  options = {
    services.efs-utils = {
      enable = mkEnableOption (mdDoc "Amazon EFS mount helper");
    };
  };

  config = mkIf cfg.enable {
    services.rpcbind.enable = true;
    environment.etc."amazon/efs/efs-utils.conf".source = "${pkgs.efs-utils}/etc/efs-utils.conf";
    environment.etc."amazon/efs/efs-utils.crt".source = "${pkgs.efs-utils}/etc/efs-utils.crt";

    environment.systemPackages = [ pkgs.efs-utils ];

    systemd.tmpfiles.rules = [
      "d /var/log/amazon/efs 0750 root root - -"
      "d /run/efs 0750 root root - -"
    ];

    systemd.services.efs-watchdog = {
      description = "Amazon EFS mount watchdog";
      before = [ "remote-fs-pre.target" ];
      after = [ "network-online.target" ];
      requires = [ "network-online.target" ];

      serviceConfig = {
        Type = "simple";
        KillMode = "process";
        ExecStart = "${pkgs.efs-utils}/bin/amazon-efs-mount-watchdog";
        Restart = "on-failure";
        RestartSec = "15";
      };
    };
  };
}
