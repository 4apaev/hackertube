# Shortcuts for the HackerTube scripts and builds. Run `make` to see the list.
# Override a variable on the command line, for example: make shot SCREEN=browse

DATA     ?= hackertube-data
DATA_URL ?= https://hackertube.org/download/hackertube-data.zip
OUT      ?= playlists.html
SIM      ?= Apple TV 4K (3rd generation)
SCREEN   ?= video:fNk_zzaMoSs
SHOT     ?= build/shot.png

DERIVED  = build/DerivedData
APP      = $(DERIVED)/Build/Products/Debug-appletvsimulator/HackerTube.app

# UDID of $(SIM) on the newest installed tvOS runtime. Evaluated only by targets that use it.
SIM_ID   = $(shell xcrun simctl list devices available -j | python3 -c 'import json, sys; \
	d = json.load(sys.stdin)["devices"]; \
	print(([x["udid"] for k in sorted(d) if "tvOS" in k for x in d[k] if x["name"] == "$(SIM)"] or [""])[-1])')

.DEFAULT_GOAL := help
.PHONY: help data playlists playlists-py assets build run shot clean

help: ## Show this list
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{ printf "  make %-14s %s\n", $$1, $$2 }'

data: ## Download the HackerTube data export into hackertube-data/
	curl -fL -o data.zip $(DATA_URL)
	unzip -o -q data.zip

playlists: ## Write playlists.html with the Swift script
	swift scripts/make-playlists.swift $(DATA) $(OUT)

playlists-py: ## Write playlists.html with the Python script
	python3 scripts/make-playlists.py $(DATA) $(OUT)

assets: ## Draw the app icon and Top Shelf images again
	swift scripts/make-assets.swift HackerTube/Assets.xcassets

build: ## Build the app for the tvOS simulator
	xcodebuild -project HackerTube.xcodeproj -scheme HackerTube -derivedDataPath $(DERIVED) \
		-destination 'platform=tvOS Simulator,name=$(SIM),OS=latest' -quiet build

run: build ## Build, install and start the app in the simulator
	@test -n "$(SIM_ID)" || { echo "No simulator named '$(SIM)'. See: xcrun simctl list devices"; exit 1; }
	xcrun simctl boot $(SIM_ID) 2>/dev/null || true
	open -a Simulator
	xcrun simctl install $(SIM_ID) $(APP)
	xcrun simctl launch $(SIM_ID) $$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' $(APP)/Info.plist)

shot: run ## Screenshot one screen: make shot SCREEN=browse SHOT=out.png
	scripts/shot.sh $(SIM_ID) '$(SCREEN)' $(SHOT)
	@echo "Wrote $(SHOT)"

clean: ## Remove build output and playlists.html
	rm -rf build *.zip $(OUT)
