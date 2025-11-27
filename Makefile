# Makefile for building and pushing Docker images to GHCR

# Usage: 
#   make build                       # build local image (latest tag)
#   make build TAG=v1.0.0            # build local image with tag v1.0.0
#   make build-push GHCR_TOKEN=xxx   # build and push multi-arch image to GHCR
#   make ghcr-login GHCR_TOKEN=xxx   # login to GHCR
#   make push TAG=v1.0.0             # push image (ensure login)
#   make clean                       # remove local image

# Defaults (override on cli)
GHCR_USER ?= $(shell git config user.name || echo "kapawit")
IMAGE_NAME ?= postgresus
TAG ?= latest
APP_VERSION ?= $(TAG)
PLATFORMS ?= linux/amd64,linux/arm64

# Derived values
IMAGE := ghcr.io/$(GHCR_USER)/$(IMAGE_NAME):$(TAG)

.PHONY: help build buildx build-push ghcr-login push clean

help:
	@echo "Makefile targets for building and pushing Docker images to GHCR"
	@echo "Variables (override as needed):"
	@echo "  GHCR_USER ($(GHCR_USER))"
	@echo "  IMAGE_NAME ($(IMAGE_NAME))"
	@echo "  TAG ($(TAG))"
	@echo "  APP_VERSION ($(APP_VERSION))"
	@echo "  PLATFORMS ($(PLATFORMS))"
	@echo "Examples:"
	@echo "  make build TAG=v1.0.0"
	@echo "  make ghcr-login GHCR_TOKEN=<YOUR_TOKEN>"
	@echo "  make build-push GHCR_TOKEN=<YOUR_TOKEN> TAG=v1.0.0"

# Build a local image using Docker (single platform)
build:
	@echo "Building local Docker image: $(IMAGE)"
	docker build -t $(IMAGE) --build-arg APP_VERSION=$(APP_VERSION) .

# Build multi-arch image using buildx, but don't push
buildx:
	@echo "Building multi-platform image (no push): $(IMAGE)"
	docker buildx build --platform=$(PLATFORMS) -t $(IMAGE) --build-arg APP_VERSION=$(APP_VERSION) --load .

# Build and push multi-platform image to GHCR
build-push:
	@echo "Building and pushing multi-platform image: $(IMAGE)"
	# Ensure buildx builder exists
	@if ! docker buildx inspect multi-builder >/dev/null 2>&1; then \
		 docker buildx create --use --name multi-builder; \
	fi
	@echo "Logging into GHCR..."
	@if [ -z "$(GHCR_TOKEN)" ]; then \
		echo "GHCR_TOKEN is required (set it via environment variable or pass to 'make')"; exit 1; \
	fi
	@echo $(GHCR_TOKEN) | docker login ghcr.io -u $(GHCR_USER) --password-stdin
	# Build and push
	docker buildx build --platform=$(PLATFORMS) -t $(IMAGE) --build-arg APP_VERSION=$(APP_VERSION) --push .

# Login to GHCR (requires GHCR_TOKEN set)
ghcr-login:
	@echo "Logging into GHCR at ghcr.io as $(GHCR_USER)"
	@if [ -z "$(GHCR_TOKEN)" ]; then \
		echo "GHCR_TOKEN is required (set it via environment variable or pass to 'make')"; exit 1; \
	fi
	@echo $(GHCR_TOKEN) | docker login ghcr.io -u $(GHCR_USER) --password-stdin

# Push local image to GHCR (single-platform tag)
push:
	@echo "Pushing image: $(IMAGE)"
	docker push $(IMAGE)

# Remove local image
clean:
	@echo "Removing local image: $(IMAGE)"
	-docker rmi $(IMAGE)

# Show current image name
image:
	@echo "Image: $(IMAGE)"
