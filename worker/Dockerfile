# because of dotnet, we always build on amd64, and target platforms in cli
# dotnet doesn't support QEMU for building or running. 
# (errors common in arm/v7 32bit) https://github.com/dotnet/dotnet-docker/issues/1537
# https://hub.docker.com/_/microsoft-dotnet
# hadolint ignore=DL3029
# to build for a different platform than your host, use --platform=<platform>
# for example, if you were on Intel (amd64) and wanted to build for ARM, you would use:
# docker buildx build --platform "linux/arm64/v8" .

# 1. Pinned SDK Image for Building
FROM ://microsoft.com AS build
WORKDIR /source

COPY *.csproj .
RUN dotnet restore

COPY . .
RUN dotnet publish -c Release -o /app --no-restore

# 2. Pinned minimal Runtime Image for production execution
FROM ://microsoft.com AS runtime
WORKDIR /app
COPY --from=build /app .

# 3. Enforce Non-Root Execution on Alpine Linux
RUN adduser -D -u 10001 appuser && chown -R appuser:appuser /app
USER 10001

ENTRYPOINT ["dotnet", "Worker.dll"]
