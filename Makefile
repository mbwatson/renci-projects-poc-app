# 📦 Load environment variables if .env file exists
ifneq (,$(wildcard .env))
  include .env
  export IMAGE TAG NAMESPACE
  NAMESPACE ?= comms
endif

# ============ 
# 📦 AUTOPHONY
# ============ 

# Auto-detect targets with help comments
PHONY_TARGETS := $(shell awk -F':.*?##' '/^[a-zA-Z0-9_.-]+:.*##/ {print $$1}' $(MAKEFILE_LIST))
.PHONY: help $(PHONY_TARGETS) 

# ========== 
# CONSTANTS
# ========== 
.DEFAULT_GOAL := help
CONTAINER_NAME := renci-projects-app

check: check-vars-IMAGE check-vars-TAG ## ✅ Check all required env vars
	@echo "✅ All required environment variables are set."

# ⚠️ Fail if variable is not set
check-vars-%:
	@ if [ -z "$(value ${*})" ]; then \
		echo "❌ Error: The '$*' variable is required but not set."; \
		echo "💡 Please define it in the .env file or pass it directly with make $@ $*=<value>"; \
		exit 1; \
	fi

##@ Help Commands

help: ## 📖 Show help
	@awk 'BEGIN {FS = ":.*?## "}; /^[a-zA-Z0-9_.-]+:.*?##/ {printf "• \033[36m%-20s\033[0m %s\n", $$1, $$2}; /^##@/ {printf "\n\033[1m%s\033[0m\n", substr($$0, 5)}' $(MAKEFILE_LIST)

##@ Docker Commands

pull: check-vars-IMAGE check-vars-TAG ## 📥 Pull the Docker image
	docker pull $(IMAGE):$(TAG)

build: check-vars-IMAGE check-vars-TAG ## 🛠️  Build the Docker image
	@echo "🧱 Building Docker image $(IMAGE):$(TAG)"
	docker build -t $(IMAGE):$(TAG) .

run: check-vars-IMAGE check-vars-TAG ## ▶️  Run the Docker container
	@echo "🚀 Running Docker image $(IMAGE):$(TAG) on port 80"
	docker run --rm -d \
	  -p 80:80 -p 443:443 \
	  --name $(CONTAINER_NAME) $(IMAGE):$(TAG)

stop: ## 🛑 Stop the running container
	@echo "🛑 Stopping Docker container '$(CONTAINER_NAME)' if running"
	docker ps -q -f name=$(CONTAINER_NAME) | grep -q . && docker stop $(CONTAINER_NAME)

rebuild: stop build run ## 🔄 Stop, build, and run fresh

push: check-vars-IMAGE check-vars-TAG ## 📤 Push the Docker image
	@echo "📦 Pushing Docker image $(IMAGE):$(TAG)"
	docker push $(IMAGE):$(TAG)

publish: build push ## 🚀 Build and push in one go

##@ Release Commands

set-version: ## 🏷️  Set the application version across all files
	@read -p "Enter new version: " VERSION; \
	if [ -z "$VERSION" ]; then \
		echo "❌ Version cannot be empty."; \
		exit 1; \
	fi; \
	echo "🏷️  Setting version to $VERSION"; \
	npm --prefix app version $VERSION --no-git-tag-version > /dev/null; \
	sed -i'' -e "s/^appVersion:.*/appVersion: \"$VERSION\"/" helm/Chart.yaml; \
	sed -i'' -e "s/  tag:.*/  tag: \"$VERSION\"/" helm/values.yaml; \
	sed -i'' -e "s/^TAG=.*/TAG=$VERSION/" .env; \
	echo "✅ Version updated to $VERSION in package.json, .env, helm/Chart.yaml, and helm/values.yaml";

release: set-version publish helm-up ## 🚀 Run a full release: set version, publish, and deploy

##@ Helm Commands
