FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY src/Claeren.PolicyApp.BFF/ .
RUN dotnet restore "Claeren.PolicyApp.BFF.csproj"
RUN dotnet publish "Claeren.PolicyApp.BFF.csproj" -c Release -o /app/publish --no-restore

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production
ENTRYPOINT ["dotnet", "Claeren.PolicyApp.BFF.dll"]
