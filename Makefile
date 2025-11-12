# 📦 Load environment variables if .env file exists
ifneq (,$(wildcard .env))
  include .env
  export IMAGE TAG NAMESPACE RELEASE_NAME
  NAMESPACE ?= comms
  RELEASE_NAME ?= renci-matrix
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

##@ Helm Commands

helm-up: check-vars-RELEASE_NAME check-vars-NAMESPACE ## 🚀 Deploy or upgrade the Helm chart
	@echo "⬆️ Deploying/Upgrading Helm chart '$(RELEASE_NAME)' in namespace '$(NAMESPACE)'"
	helm upgrade --install $(RELEASE_NAME) ./helm --namespace $(NAMESPACE)

helm-down: check-vars-RELEASE_NAME check-vars-NAMESPACE ## 🗑️ Uninstall the Helm chart
	@echo "⬇️ Uninstalling Helm chart '$(RELEASE_NAME)' from namespace '$(NAMESPACE)'"
	helm uninstall $(RELEASE_NAME) --namespace $(NAMESPACE)

helm-lint: ## 🔎 Lint the Helm chart
	@echo "🔎 Linting Helm chart"
	helm lint ./helm

helm-template: check-vars-RELEASE_NAME check-vars-NAMESPACE ## 📄 Template the Helm chart
	@echo "📄 Templating Helm chart '$(RELEASE_NAME)' in namespace '$(NAMESPACE)'"
	helm template $(RELEASE_NAME) ./helm --namespace $(NAMESPACE)

helm-status: check-vars-RELEASE_NAME check-vars-NAMESPACE ## 📊 Check the status of the Helm release
	@echo "📊 Checking status of Helm release '$(RELEASE_NAME)' in namespace '$(NAMESPACE)'"
	helm status $(RELEASE_NAME) --namespace $(NAMESPACE)

helm-test: check-vars-RELEASE_NAME check-vars-NAMESPACE ## 🧪 Run Helm tests
	@echo "🧪 Running tests for Helm release '$(RELEASE_NAME)' in namespace '$(NAMESPACE)'"
	helm test $(RELEASE_NAME) --namespace $(NAMESPACE)
