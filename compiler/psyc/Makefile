.PHONY: install
install: nupkg/*.nupkg
	dotnet tool install --global --add-source ./nupkg psyche

nupkg/*.nupkg:
	dotnet pack --configuration Debug

.PHONY: clean
clean:
	rm nupkg/*.nupkg
