NUGET_SOURCE ?= https://nuget.pkg.github.com/0918nobita/index.json
GITHUB_USER ?= 0918nobita

.PHONY: push-psyc
push-psyc: nuget.config psyc.*.nupkg
	dotnet nuget push psyc.*.nupkg -s "${NUGET_SOURCE}" -k GitHubPackageRegistry

.PHONY: push-psyvm
push-psyvm: nuget.config psyvm.*.nupkg
	dotnet nuget push psyvm.*.nupkg -s "${NUGET_SOURCE}" -k GitHubPackageRegistry

.PHONY: install-from-gpr
install-from-gpr: nuget.config
	dotnet tool install --global --add-source $(NUGET_SOURCE) --configfile nuget.config psyc
	dotnet tool install --global --add-source $(NUGET_SOURCE) --configfile nuget.config psyvm

.PHONY: uninstall
uninstall:
	dotnet tool uninstall --global psyc
	dotnet tool uninstall --global psyvm

nuget.config:
ifndef GITHUB_TOKEN
	$(error GITHUB_TOKEN environment variable not set)
endif
	cp ./nuget.base.config nuget.config
	sed -i "s/NUGET_SOURCE/$(subst /,\/,$(NUGET_SOURCE))/g" nuget.config
	sed -i "s/GITHUB_USER/$(GITHUB_USER)/g" nuget.config
	sed -i "s/GITHUB_TOKEN/$(GITHUB_TOKEN)/g" nuget.config

*.nupkg:
	dotnet pack ./compiler/psyc/psyc.fsproj --configuration Release --output "${PWD}"
	dotnet pack ./compiler/psyvm/psyvm.fsproj --configuration Release --output "${PWD}"

.PHONY: clean
clean:
	rm nuget.config *.nupkg
