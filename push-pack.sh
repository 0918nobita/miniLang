dotnet pack ./compiler/src/psyc/psyc.fsproj --configuration Release --output "${PWD}"

NUGET_CONFIG="$(cat nuget.base.config)"
NUGET_CONFIG="${NUGET_CONFIG//GITHUB_TOKEN/$GITHUB_TOKEN}"

echo $NUGET_CONFIG > ./nuget.config

dotnet nuget push *.nupkg \
  -s "${NUGET_SOURCE}" \
  -k GitHubPackageRegistry
