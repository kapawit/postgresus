# Makefile for building and pushing Docker images to GCP Artifact Registry

# Usage: 
#   make build                       # build local image (latest tag)
#   make build TAG=v1.0.0            # build local image with tag v1.0.0
#   make build-push GCP_PROJECT=xxx  # build and push multi-arch image to GCP Artifact Registry
#   make gcp-login                   # configure docker for GCP Artifact Registry
#   make push TAG=v1.0.0             # push image (ensure login)
#   make clean                       # remove local image

# Defaults (override on cli)
GCP_PROJECT ?= dipay-staging-experiment
REPOSITORY ?= tools
IMAGE_NAME ?= postgresus
TAG ?= latest
APP_VERSION ?= $(TAG)
PLATFORMS ?= linux/amd64,linux/arm64

# Derived values
IMAGE := asia-southeast2-docker.pkg.dev/$(GCP_PROJECT)/$(REPOSITORY)/$(IMAGE_NAME):$(TAG)

.PHONY: help build buildx build-push gcp-login push clean

help:
	@echo "Makefile targets for building and pushing Docker images to GCP Artifact Registry"
	@echo "Variables (override as needed):"
	@echo "  GCP_PROJECT ($(GCP_PROJECT))"
	@echo "  REPOSITORY ($(REPOSITORY))"
	@echo "  IMAGE_NAME ($(IMAGE_NAME))"
	@echo "  TAG ($(TAG))"
	@echo "  APP_VERSION ($(APP_VERSION))"
	@echo "  PLATFORMS ($(PLATFORMS))"
	@echo "Examples:"
	@echo "  make build TAG=v1.0.0"
	@echo "  make gcp-login"
	@echo "  make build-push GCP_PROJECT=<YOUR_PROJECT_ID> REPOSITORY=<REPO> TAG=v1.0.0"

# Build a local image using Docker (single platform)
build:
	@echo "Building local Docker image: $(IMAGE)"
	docker build -t $(IMAGE) --build-arg APP_VERSION=$(APP_VERSION) .

# Build multi-arch image using buildx, but don't push
buildx:
	@echo "Building multi-platform image (no push): $(IMAGE)"
	docker buildx build --platform=$(PLATFORMS) -t $(IMAGE) --build-arg APP_VERSION=$(APP_VERSION) --load .

# Build and push multi-platform image to GCP Artifact Registry
build-push:
	@echo "Building and pushing multi-platform image: $(IMAGE)"
	# Ensure buildx builder exists
	@if ! docker buildx inspect multi-builder >/dev/null 2>&1; then \
		 docker buildx create --use --name multi-builder; \
	fi
	@echo "Configuring Docker for GCP Artifact Registry..."
	gcloud auth configure-docker asia-southeast2-docker.pkg.dev --quiet
	# Build and push
	docker buildx build --platform=$(PLATFORMS) -t $(IMAGE) --build-arg APP_VERSION=$(APP_VERSION) --push .

# Configure Docker for GCP Artifact Registry
gcp-login:
	@echo "Configuring Docker for GCP Artifact Registry at asia-southeast2-docker.pkg.dev"
	gcloud auth configure-docker asia-southeast2-docker.pkg.dev --quiet

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
