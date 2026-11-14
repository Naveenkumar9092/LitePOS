# Multi-stage Dockerfile for .NET 10 Web API on Render / Cloud Containers
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy project files and restore dependencies
COPY BillingPOS/BillingPOS.Domain/BillingPOS.Domain.csproj BillingPOS/BillingPOS.Domain/
COPY BillingPOS/BillingPOS.Application/BillingPOS.Application.csproj BillingPOS/BillingPOS.Application/
COPY BillingPOS/BillingPOS.Infrastructure/BillingPOS.Infrastructure.csproj BillingPOS/BillingPOS.Infrastructure/
COPY BillingPOS/BillingPOS.Api/BillingPOS.Api.csproj BillingPOS/BillingPOS.Api/

RUN dotnet restore BillingPOS/BillingPOS.Api/BillingPOS.Api.csproj

# Copy all source files and publish release
COPY BillingPOS/ BillingPOS/
WORKDIR /src/BillingPOS/BillingPOS.Api
RUN dotnet publish -c Release -o /app/publish --no-restore

# Final runtime image
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .

# Default environment variables for cloud container
ENV ASPNETCORE_ENVIRONMENT=Production
ENV PORT=8080
ENV EnableSwagger=true
ENV DatabaseProvider=Sqlite
ENV ConnectionStrings__SqliteConnection="Data Source=LitePOS_Cloud.db"

# Expose Render standard container port
EXPOSE 8080

ENTRYPOINT ["dotnet", "BillingPOS.Api.dll"]
