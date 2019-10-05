NUGET_SOURCE ?= https://nuget.pkg.github.com/0918nobita/index.json
GITHUB_USER ?= 0918nobita

.PHONY: push
push: nuget.config *.nupkg
	dotnet nuget push *.nupkg -s "${NUGET_SOURCE}" -k GitHubPackageRegistry

.PHONY: install-from-gpr
install-from-gpr: nuget.config
	dotnet tool install --global --add-source $(NUGET_SOURCE) --configfile nuget.config psyche

.PHONY: uninstall
uninstall:
	dotnet tool uninstall --global psyche

nuget.config:
ifndef GITHUB_TOKEN
	$(error GITHUB_TOKEN environment variable not set)
endif
	cp ./nuget.base.config nuget.config
	sed -i "s/NUGET_SOURCE/$(subst /,\/,$(NUGET_SOURCE))/g" nuget.config
	sed -i "s/GITHUB_USER/$(GITHUB_USER)/g" nuget.config
	sed -i "s/GITHUB_TOKEN/$(GITHUB_TOKEN)/g" nuget.config

*.nupkg:
	dotnet pack ./compiler/src/psyc/psyc.fsproj --configuration Release --output "${PWD}"

.PHONY: clean
clean:
	rm nuget.config *.nupkg
