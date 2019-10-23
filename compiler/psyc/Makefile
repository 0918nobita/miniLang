.PHONY: install
install: nupkg/*.nupkg
	dotnet tool install --global --add-source ./nupkg psyc

nupkg/*.nupkg:
	dotnet pack --configuration Debug

.PHONY: clean
clean:
	rm nupkg/*.nupkg
