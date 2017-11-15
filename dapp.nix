dapp: with dapp; solidityPackage {
  name = "ds-proxy";
  deps = with dappsys; [ds-auth ds-note ds-test];
  src = ./src;
}
