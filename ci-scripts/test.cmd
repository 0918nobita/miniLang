dotnet tool restore
dotnet paket restore
dotnet fake -v build -t test %*
