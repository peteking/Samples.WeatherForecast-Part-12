ARG VERSION=5.0-alpine

FROM mcr.microsoft.com/dotnet/runtime-deps:${VERSION} AS base
WORKDIR /app
EXPOSE 8080
HEALTHCHECK --interval=60s --timeout=3s --retries=3 \
    CMD wget localhost:8080/health -q -O - > /dev/null 2>&1

FROM mcr.microsoft.com/dotnet/sdk:${VERSION} AS build
WORKDIR /code

# Copy and restore as distinct layers
COPY ["src/Samples.WeatherForecast.Api/Samples.WeatherForecast.Api.csproj", "src/Samples.WeatherForecast.Api/Samples.WeatherForecast.Api.csproj"]
COPY ["test/Samples.WeatherForecast.Api.UnitTest/Samples.WeatherForecast.Api.UnitTest.csproj", "test/Samples.WeatherForecast.Api.UnitTest/"]

RUN dotnet restore "src/Samples.WeatherForecast.Api/Samples.WeatherForecast.Api.csproj" -r linux-musl-x64
RUN dotnet restore "test/Samples.WeatherForecast.Api.UnitTest/Samples.WeatherForecast.Api.UnitTest.csproj" -r linux-musl-x64
COPY . .

# Build
RUN dotnet build \
    "src/Samples.WeatherForecast.Api/Samples.WeatherForecast.Api.csproj" \
    -c Release \
    --runtime linux-musl-x64 \
    --no-restore    

RUN dotnet build \
    "test/Samples.WeatherForecast.Api.UnitTest/Samples.WeatherForecast.Api.UnitTest.csproj" \
    -c Release \
    -r linux-musl-x64 \
    --no-restore    

# Unit test runner
FROM build AS unit-test
WORKDIR /code/test/Samples.WeatherForecast.Api.UnitTest
ENTRYPOINT dotnet test \
    -c Release \
    --runtime linux-musl-x64 \
    --no-restore \
    --no-build \
    --logger "trx;LogFileName=test_results_unit_test.trx" \
    -p:CollectCoverage=true \
    -p:CoverletOutput="TestResults/coverage.info" \
    -p:CoverletOutputFormat=lcov

FROM build AS publish
RUN dotnet publish \
    "src/Samples.WeatherForecast.Api/Samples.WeatherForecast.Api.csproj" \
    -c Release \
    -o /app/publish \
    --runtime linux-musl-x64 \
    --self-contained=true \
    -- no-restore \
    -- no-build \
    -p:PublishReadyToRun=true \
    -p:PublishTrimmed=true

# Final stage/image
FROM base AS final

RUN addgroup -S dotnetgroup && \
    adduser -S dotnet
USER dotnet

WORKDIR /app
COPY --chown=dotnet:dotnetgroup --from=publish /app/publish .
ENV ASPNETCORE_URLS=http://*:8080
ENTRYPOINT ["./Samples.WeatherForecast.Api"]