.PHONY: package

.EXPORT_ALL_VARIABLES:
SOME_VAR = "egal"

buildImageAmd64:
	docker buildx build --platform linux/amd64 --tag nauni1977/owasp-db-cache-amd64 --load .

buildImageArm64:
	docker buildx build --platform linux/arm64 --tag nauni1977/owasp-db-cache-arm64 --load .

buildImageMultiArch:
	docker buildx build --platform linux/arm64,linux/amd64 --tag nauni1977/owasp-db-cache --push .

