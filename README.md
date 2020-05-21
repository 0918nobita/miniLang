# Psyche

[![GitHub Actions](https://github.com/0918nobita/psyche/workflows/Build/badge.svg)](https://github.com/0918nobita/psyche/actions)  [![Twitter](https://img.shields.io/badge/Twitter-%40psychelang-blue?style=flat-square&logo=twitter)](https://twitter.com/psychelang)

Programming language

For more details about the language specification, see [wiki](https://github.com/0918nobita/psyche/wiki).

Made with ❤️ in Japan

## Requirements

- .NET Core Version 3 or newer

## Setup

```bash
dotnet tool restore
dotnet paket restore
```

## Build

### Debug Build

```bash
dotnet fake build
```

### Release Build

```bash
dotnet fake build -t release
```

## Run

```bash
dotnet run --project src/Compiler # --no-build
```

## Test

```bash
dotnet fake build -t test
```

## References

### [Paket](https://fsprojects.github.io/Paket/index.html)

Each project requires `paket.references` file.

After updating `/paket.dependencies` :

```bash
dotnet paket install
```

To update libraries,

```bash
dotnet paket update
```

### [FAKE](https://fake.build/)

Scripting at `/build.fsx`

```bash
dotnet fake build -t clean  # Run "Clean" target
dotnet fake build           # Run default target
```

## License

This software is released under the MIT License, see LICENSE.
