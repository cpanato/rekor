##################
# release section
##################

# used when releasing together with GCP CloudBuild
.PHONY: release
release:
	CLIENT_LDFLAGS="$(CLI_LDFLAGS)" SERVER_LDFLAGS="$(SERVER_LDFLAGS)" goreleaser release --rm-dist --timeout 60m

# used when need to validate the goreleaser
.PHONY: snapshot
snapshot:
	CLIENT_LDFLAGS="$(CLI_LDFLAGS)" SERVER_LDFLAGS="$(SERVER_LDFLAGS)" goreleaser release --skip-sign --skip-publish --snapshot --rm-dist

###########################
# sign with GCP KMS section
###########################

.PHONY: sign-rekor-server-release
sign-rekor-server-release:
	cosign sign --key "gcpkms://projects/$(PROJECT_ID)/locations/$(KEY_LOCATION)/keyRings/$(KEY_RING)/cryptoKeys/$(KEY_NAME)/versions/$(KEY_VERSION)" -a GIT_HASH=$(GIT_HASH) -a GIT_VERSION=$(GIT_VERSION) $(KO_PREFIX)/rekor-server:$(GIT_VERSION)

.PHONY: sign-rekor-cli-release
sign-rekor-cli-release:
	cosign sign --key "gcpkms://projects/$(PROJECT_ID)/locations/$(KEY_LOCATION)/keyRings/$(KEY_RING)/cryptoKeys/$(KEY_NAME)/versions/$(KEY_VERSION)" -a GIT_HASH=$(GIT_HASH) -a GIT_VERSION=$(GIT_VERSION) $(KO_PREFIX)/rekor-cli:$(GIT_VERSION)

.PHONY: sign-trillian-server-release
sign-trillian-server-release:
	cosign sign --key "gcpkms://projects/$(PROJECT_ID)/locations/$(KEY_LOCATION)/keyRings/$(KEY_RING)/cryptoKeys/$(KEY_NAME)/versions/$(KEY_VERSION)" -a GIT_HASH=$(GIT_HASH) -a GIT_VERSION=$(GIT_VERSION) $(KO_PREFIX)/trillian_log_server:$(GIT_VERSION)

.PHONY: sign-trillian-signer-release
sign-trillian-signer-release:
	cosign sign --key "gcpkms://projects/$(PROJECT_ID)/locations/$(KEY_LOCATION)/keyRings/$(KEY_RING)/cryptoKeys/$(KEY_NAME)/versions/$(KEY_VERSION)" -a GIT_HASH=$(GIT_HASH) -a GIT_VERSION=$(GIT_VERSION) $(KO_PREFIX)/trillian_log_signer:$(GIT_VERSION)

.PHONY: sign-container-release
sign-container-release: ko sign-rekor-server-release sign-rekor-cli-release ko-trillian sign-trillian-server-release sign-trillian-signer-release

######################
# sign keyless section
######################

.PHONY: sign-keyless-rekor-server-release
sign-keyless-rekor-server-release:
	cosign sign --force -a GIT_HASH=$(GIT_HASH) -a GIT_VERSION=$(GIT_VERSION) $(KO_PREFIX)/rekor-server:$(GIT_VERSION)

.PHONY: sign-keyless-rekor-cli-release
sign-keyless-rekor-cli-release:
	cosign sign --force -a GIT_HASH=$(GIT_HASH) -a GIT_VERSION=$(GIT_VERSION) $(KO_PREFIX)/rekor-cli:$(GIT_VERSION)

.PHONY: sign-keyless-trillian-server-release
sign-keyless-trillian-server-release:
	cosign sign --force -a GIT_HASH=$(GIT_HASH) -a GIT_VERSION=$(GIT_VERSION) $(KO_PREFIX)/trillian_log_server:$(GIT_VERSION)

.PHONY: sign-keyless-trillian-signer-release
sign-keyless-trillian-signer-release:
	cosign sign --force -a GIT_HASH=$(GIT_HASH) -a GIT_VERSION=$(GIT_VERSION) $(KO_PREFIX)/trillian_log_signer:$(GIT_VERSION)

.PHONY: sign-keyless-release
sign-keyless-release: sign-keyless-rekor-server-release sign-keyless-rekor-cli-release sign-keyless-trillian-server-release sign-keyless-trillian-signer-release

####################
# copy image to GHCR
####################

.PHONY: copy-rekor-server-signed-release-to-ghcr
copy-cosign-signed-release-to-ghcr:
	cosign copy $(KO_PREFIX)/rekor-server:$(GIT_VERSION) $(GHCR_PREFIX)/rekor-server:$(GIT_VERSION)

.PHONY: copy-rekor-cli-signed-release-to-ghcr
copy-cosigned-signed-release-to-ghcr:
	cosign copy $(KO_PREFIX)/rekor-cli:$(GIT_VERSION) $(GHCR_PREFIX)/rekor-cli:$(GIT_VERSION)

.PHONY: copy-signed-release-to-ghcr
copy-signed-release-to-ghcr: copy-rekor-server-signed-release-to-ghcr copy-rekor-cli-signed-release-to-ghcr

## --------------------------------------
## Dist / maybe we can deprecate
## --------------------------------------

.PHONY: dist-cli
dist-cli:
	mkdir -p dist/
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags $(CLI_LDFLAGS) -o dist/rekor-cli-linux-amd64 ./cmd/rekor-cli
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -trimpath -ldflags $(CLI_LDFLAGS) -o dist/rekor-cli-linux-arm64 ./cmd/rekor-cli
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -trimpath -ldflags $(CLI_LDFLAGS) -o dist/rekor-cli-darwin-amd64 ./cmd/rekor-cli
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -trimpath -ldflags $(CLI_LDFLAGS) -o dist/rekor-cli-darwin-arm64 ./cmd/rekor-cli
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -trimpath -ldflags $(CLI_LDFLAGS) -o dist/rekor-cli-windows-amd64.exe ./cmd/rekor-cli

.PHONY: dist-server
dist-server:
	mkdir -p dist/
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags $(SERVER_LDFLAGS) -o dist/rekor-server-linux-amd64 ./cmd/rekor-server

.PHONY: dist
dist: dist-server dist-cli
