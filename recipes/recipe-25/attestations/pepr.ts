import { PeprModule } from "pepr";
import cfg from "./package.json";
import { Attestations } from "./capabilities/attestations";

new PeprModule(cfg, [
  Attestations,
]);
