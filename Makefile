# L123 Makefile — convenience targets for the WK3 (Lotus 1-2-3 R3 import)
# build mode toggle. The default committed state is "WK3 off / public clean":
# pure crates.io IronCalc, no path dep on a local IronCalc clone. Toggling
# WK3 on edits one `Cargo.toml` in place — that edit is NOT meant to be
# committed.
#
# `ironcalc_lotus` depends on the *published* `ironcalc_base`, so enabling
# WK3 needs no `[patch.crates-io]` redirect: the graph still resolves to a
# single copy of that crate. (It used to, back when `lotus` path-depended
# on `../IronCalc/base`.)
#
# Run `make` (or `make help`) for the full target list. Targets are
# idempotent — running wk3-on twice is a no-op the second time.

ENGINE_TOML := crates/l123-engine/Cargo.toml

# Marker line we use to detect "WK3 currently on": the uncommented
# `ironcalc_lotus` path dep in the engine manifest.
WK3_MARKER  := ^ironcalc_lotus = { path = "../../../IronCalc/lotus" }$$

.DEFAULT_GOAL := help

.PHONY: help wk3-on wk3-off wk3-status build build-wk3 test test-wk3 clean

help: ## Show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

wk3-on: ## Uncomment the ironcalc_lotus path dep
	@sed -i.bak 's|^# ironcalc_lotus = { path = "../../../IronCalc/lotus" }$$|ironcalc_lotus = { path = "../../../IronCalc/lotus" }|' $(ENGINE_TOML)
	@rm -f $(ENGINE_TOML).bak
	@echo "WK3: enabled. Use --features wk3 (e.g. cargo build -p l123 --features wk3)."

wk3-off: ## Restore the public-clean state (also reverts Cargo.lock if dirtied by a wk3 build)
	@sed -i.bak 's|^ironcalc_lotus = { path = "../../../IronCalc/lotus" }$$|# ironcalc_lotus = { path = "../../../IronCalc/lotus" }|' $(ENGINE_TOML)
	@rm -f $(ENGINE_TOML).bak
	@git checkout -- Cargo.lock 2>/dev/null || true
	@echo "WK3: disabled. Plain cargo build / test will use crates.io IronCalc."

wk3-status: ## Report whether WK3 deps are currently uncommented
	@if grep -qE '$(WK3_MARKER)' $(ENGINE_TOML); then \
		echo "WK3: ENABLED  (path deps uncommented; --features wk3 required to compile in WK3 code)"; \
	else \
		echo "WK3: disabled (default public-clean state)"; \
	fi

build: wk3-off ## wk3-off, then `cargo build --workspace`
	cargo build --workspace

build-wk3: wk3-on ## wk3-on, then `cargo build -p l123 --features wk3`
	cargo build -p l123 --features wk3

test: wk3-off ## wk3-off, then `cargo test --workspace`
	cargo test --workspace

test-wk3: wk3-on ## wk3-on, then `cargo test --workspace --features l123-ui/wk3`
	cargo test --workspace --features l123-ui/wk3

clean: ## Run `cargo clean` (removes target/)
	cargo clean
