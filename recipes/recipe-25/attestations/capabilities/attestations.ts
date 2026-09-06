import {
  Capability,
  a,
} from "pepr";

export const Attestations = new Capability({
  name: "attestations",
  description: "Block pod creation requests that don't have container attestations.",
  namespaces: [],
});

const { When } = Attestations;

When(a.Namespace)
  .IsCreated()
  .Mutate(ns => ns.RemoveLabel("remove-me"));
