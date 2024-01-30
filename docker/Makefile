IMG := r0ckstar/litellm-proxy

.PHONY: docker-build
docker-build:
	docker build -t ${IMG} .

.PHONY: docker-push
docker-push: docker-build
	docker push ${IMG}
