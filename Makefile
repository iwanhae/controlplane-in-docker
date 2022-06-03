IP=192.168.0.33
DOCKER_IMAGE=iwanhae/controlplane-in-docker
DOCKER_TAG=test

run: build
	docker run -it --rm --name test \
		-p 6443:6443 -p 8132:8132 \
		-e IP=${IP} \
		${DOCKER_IMAGE}:${DOCKER_TAG}

push: build
	docker push ${DOCKER_IMAGE}:${DOCKER_TAG}

build:
	docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .

exec:
	docker exec -it test bash