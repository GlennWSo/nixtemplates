{
  outputs = {self}: {
    templates = {
      rust = {
        description = "A rust development flake";
        path = ./rust;
      };
    };
  };
}
