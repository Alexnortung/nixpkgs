# Inspired by: https://discourse.nixos.org/t/how-to-setup-s3fs-mount/6283/2

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.s3fs-fuse;

  mountModule = types.submodule {
    options = {
      mountPoint = mkOption {
        type = types.str;
        description = lib.mdDoc ''
          The point where to mount the s3 filesystem. (second argument to s3fs)
        '';
        example = ''
          "/mnt/s3"
        '';
      };

      bucket = mkOption {
        type = types.str;
        description = lib.mdDoc ''
          The name of the bucket you want to mount. (first argument to s3fs)
        '';
      };

      options = mkOption {
        type = types.listOf types.str;
        description = lib.mdDoc ''
          The options passed to the s3fs command
        '';
        example = ''
          [
            "passwd_file=/root/.passwd-s3fs"
            "use_path_request_style"
            "allow_other"
            "url=https://ap-south-1.linodeobjects.com/" # Linode object storage
          ]
        '';
      };
    };
  };
in
{
  options = {
    services.s3fs-fuse = {
      enable = mkEnableOption (lib.mdDoc ''
        Whether to enable s3fs-fuse mounts.
      '');

      mounts = mkOption {
        type = types.attrsOf mountModule;
        description = lib.mdDoc ''
          A set of the s3 filesystems you want to mount.
          The name of the attribute is only used for naming the running service.
        '';
      };
    };
  };

  config = mkIf cfg.enable {

    systemd.services = mapAttrs' (name: mountSet:
      let
        mount = mountSet.mountPoint;
        bucket = mountSet.bucket;
        options = mountSet.options;
      in
        nameValuePair
          "s3fs-${name}" {
            description = "S3FS mount";
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              ExecStartPre = [
                "${pkgs.coreutils}/bin/mkdir -m 0500 -pv ${mount}"
                "${pkgs.e2fsprogs}/bin/chattr +i ${mount}"  # Stop files being accidentally written to unmounted directory
              ];
              ExecStart =
                "${pkgs.s3fs}/bin/s3fs ${bucket} ${mount} -f "
                  + lib.concatMapStringsSep " " (opt: "-o ${opt}") options;
              ExecStopPost = "-${pkgs.fuse}/bin/fusermount -u ${mount}";
              KillMode = "process";
              Restart = "on-failure";
            };
          }) cfg.mounts;
  };
}
