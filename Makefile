default: docker_build

DOCKER_IMAGE ?= nginx-site-demo
GIT_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)

ifeq ($(GIT_BRANCH), master)
	DOCKER_TAG = latest
else
	DOCKER_TAG = $(GIT_BRANCH)
endif

docker_build:
	@docker build \
	  --build-arg VCS_REF=`git rev-parse --short HEAD` \
	  --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		--build-arg VCS_URL="https://github.com/geoffh1977/nginx-site-demo.git" \
	  -t $(DOCKER_IMAGE):$(DOCKER_TAG) .

docker_push:
	# Push to DockerHub
	docker push $(DOCKER_IMAGE):$(DOCKER_TAG)

test:
	docker run $(DOCKER_IMAGE):$(DOCKER_TAG) version --client
