{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ic-keysmith
    quill
    quill-qr
  ];
}
