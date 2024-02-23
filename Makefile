.PHONY: package

.EXPORT_ALL_VARIABLES:
SOME_VAR = "egal"

buildImageAmd64:
	docker buildx build --platform linux/amd64 --tag nauni1977/owasp-db-cache:dev --load .

buildImageArm64:
	docker buildx build --platform linux/arm64 --tag nauni1977/owasp-db-cache:dev --load .

buildImageMultiArch:
	docker buildx build --platform linux/arm64,linux/amd64 --tag nauni1977/owasp-db-cache:dev --push .

runLocalPullAndStart:
	docker pull nauni1977/owasp-db-cache:dev
	docker run --rm --name owasp-db -p 3306:3306 -v owasp-db:/var/lib/mysql -v owasp-config:/var/lib/owasp-db-cache -e NVD_API_KEY=6e54e143-9350-4615-971d-7b7a7242ab48 nauni1977/owasp-db-cache:dev

runLocalBuildAndStart: buildImageArm64
	docker run --rm --name owasp-db -p 3306:3306 -v owasp-db:/var/lib/mysql -v owasp-config:/var/lib/owasp-db-cache -e NVD_API_KEY=6e54e143-9350-4615-971d-7b7a7242ab48 nauni1977/owasp-db-cache:dev
	docker logs -f owasp-db

runLocalStop:
	docker stop owasp-db

