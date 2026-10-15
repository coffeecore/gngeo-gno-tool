GNO_SERVICE := gno

GNGEO_REPO ?= https://github.com/coffeecore/gngeo-steward-fu.git
GNGEO_REF ?= trimui-model-s

FORCE ?= 0

.PHONY: gno gno-dir gno-image

gno-image:
	GNGEO_REPO="$(GNGEO_REPO)" \
	GNGEO_REF="$(GNGEO_REF)" \
	docker compose build "$(GNO_SERVICE)" --no-cache

gno:
	@test -n "$(ROM)" || { \
		echo 'ERROR: ROM is required'; \
		echo 'Usage: make gno ROM="/path/to/mslug.zip"'; \
		exit 1; \
	}
	@set -eu; \
	ROM_ABS="$$(realpath "$(ROM)")"; \
	test -f "$$ROM_ABS" || { \
		echo "ERROR: ROM not found: $$ROM_ABS" >&2; \
		exit 1; \
	}; \
	ROM_DIR="$$(dirname "$$ROM_ABS")"; \
	ROM_FILE="$$(basename "$$ROM_ABS")"; \
	test -f "$$ROM_DIR/neogeo.zip" || { \
		echo "ERROR: neogeo.zip not found in: $$ROM_DIR" >&2; \
		exit 1; \
	}; \
	GNGEO_REPO="$(GNGEO_REPO)" \
	GNGEO_REF="$(GNGEO_REF)" \
	docker compose run \
		--rm \
		--build \
		--no-deps \
		--user "$$(id -u):$$(id -g)" \
		--volume "$$ROM_DIR:/roms" \
		--env FORCE="$(FORCE)" \
		"$(GNO_SERVICE)" \
		single "/roms/$$ROM_FILE"

gno-dir:
	@test -n "$(ROM_DIR)" || { \
		echo 'ERROR: ROM_DIR is required'; \
		echo 'Usage: make gno-dir ROM_DIR="/path/to/Neo Geo"'; \
		exit 1; \
	}
	@set -eu; \
	ROM_DIR_ABS="$$(realpath "$(ROM_DIR)")"; \
	test -d "$$ROM_DIR_ABS" || { \
		echo "ERROR: directory not found: $$ROM_DIR_ABS" >&2; \
		exit 1; \
	}; \
	test -f "$$ROM_DIR_ABS/neogeo.zip" || { \
		echo "ERROR: neogeo.zip not found in: $$ROM_DIR_ABS" >&2; \
		exit 1; \
	}; \
	GNGEO_REPO="$(GNGEO_REPO)" \
	GNGEO_REF="$(GNGEO_REF)" \
	docker compose run \
		--rm \
		--build \
		--no-deps \
		--user "$$(id -u):$$(id -g)" \
		--volume "$$ROM_DIR_ABS:/roms" \
		--env FORCE="$(FORCE)" \
		"$(GNO_SERVICE)" \
		dir /roms
