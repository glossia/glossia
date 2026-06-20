---
title: "Why model belongs in L10N.md"
date: "2026-05-26"
description: "Why the next version of the spec needs to make model choice explicit instead of hiding it inside translation tooling."
author: "Pedro Piñera"
---

I keep seeing the same pattern in AI translation workflows. Teams put a lot of
thought into glossary rules, tone, validation commands, and file scoping, but
they leave the model choice as an implementation detail of the tool. That feels
convenient until it stops being convenient.

The model is not an implementation detail anymore. It shapes the output too
much.

Two repositories can carry the same `L10N.md` guidance and still produce very
different translations because one run went through a fast model and the other
through a more capable one. The wording changes. The discipline around
formatting changes. The ability to respect subtle instructions changes. If that
decision lives outside the repository, the repository is no longer the full
contract.

## A global default stops working surprisingly fast

A single model default sounds fine when you look at translation as one task.
Most repositories are not one task.

A marketing page, an error catalog, release notes, and a legal document do not
need the same trade-off. Some scopes need raw speed. Some need lower cost. Some
need a model that is better at following structure and tone without drifting.
We already introduced scoped `L10N.md` files because translation context is not
uniform across a repository. Model selection follows the same logic.

If the spec can describe that `docs/` and `website/` need different rules, it
should also be able to describe that they need different models.

## This is really about reproducibility

What I want from L10N.md is not just a place to write helpful notes for a tool.
I want a repository to describe the translation system it expects with enough
precision that another person, or another tool, can reproduce the intent.

That does not mean freezing every runtime detail into the spec. It means
capturing the decisions that materially affect output quality.

Model choice clearly does.

Right now, if a team upgrades a translation tool and that tool quietly changes
its default model, the output can change even if the repository did not. That
is the kind of hidden coupling I want to push out of the shadows. When a
translation quality change is intentional, it should show up in code review next
to the rest of the translation context.

## I do not want the spec to become vendor theater

The obvious risk here is turning the spec into a parade of provider-specific
model names that age badly. I do not want that.

The point is not to make L10N.md chase every model release. The point is to let
repositories express a stable decision about the class of model they expect for
a scope, and let tooling resolve that decision sensibly. Some tools might map it
to an exact provider and model identifier. Others might map it to an internal
profile. Both are fine as long as the intent is explicit.

In other words, I care more about making the decision visible than about forcing
every implementation to encode it the same way.

## Why add it now

When I first put the spec together, I wanted the machine-readable surface to
stay as small as possible. I still want that. Small specs are easier to adopt
and harder to misread.

But minimalism should not turn into denial. If there is a knob that
substantially changes the outcome, and if teams are already reaching for that
knob in practice, leaving it out of the spec does not keep the system simple. It
just moves complexity into undocumented tool configuration.

That is why I want the next version of L10N.md to grow a `model` field. Not
because more configuration is inherently better, but because this particular
piece of configuration has become part of translation context itself.
