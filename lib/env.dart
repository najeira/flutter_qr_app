class Environment {
  const Environment._();

  static const flavor = String.fromEnvironment(
    "FLAVOR",
    defaultValue: "dev",
  );

  static const isFlavorDev = flavor == "dev";

  static const isFlavorProd = flavor == "prod";
}
