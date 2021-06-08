$IMAGE_NAME_AND_TAG="samples-weatherforecast-unit-test:v12"

Write-Output "Unit tests [build]"
docker build --target unit-test -t $IMAGE_NAME_AND_TAG .

Write-Output "Unit tests [run]"
docker run --rm -v "${pwd}\TestResults:/code/test/Samples.WeatherForecast.Api.UnitTest/TestResults/" $IMAGE_NAME_AND_TAG