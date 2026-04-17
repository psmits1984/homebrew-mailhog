using Claeren.PolicyApp.BFF.Infrastructure.Auth;
using Claeren.PolicyApp.BFF.Infrastructure.Resilience;
using Claeren.PolicyApp.BFF.Services.Implementations;
using Claeren.PolicyApp.BFF.Services.Interfaces;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);
var config = builder.Configuration;
var useMock = config.GetValue<bool>("Features:MockCcs");

builder.Services.AddControllers();

// Authenticatie — Keycloak in productie, eigen JWT in development/mock
if (useMock)
{
    using var sp = builder.Services.BuildServiceProvider();
    var secret = System.Text.Encoding.UTF8.GetBytes(config["Jwt:Secret"]!);
    builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddJwtBearer(o =>
        {
            o.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                ValidIssuer = config["Jwt:Issuer"],
                ValidAudience = config["Jwt:Audience"],
                IssuerSigningKey = new Microsoft.IdentityModel.Tokens.SymmetricSecurityKey(secret),
            };
        });
    builder.Services.AddScoped<IAuthService, AuthService>();
    builder.Services.AddScoped<ICcsService, MockCcsService>();
}
else
{
    // Keycloak validatie via OIDC discovery
    builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddJwtBearer(o =>
        {
            o.Authority = config["Keycloak:Authority"];
            o.Audience = config["Keycloak:ClientId"];
            o.RequireHttpsMetadata = true;
        });

    // Keycloak options
    builder.Services.Configure<KeycloakOptions>(config.GetSection(KeycloakOptions.Section));

    // Keycloak auth service
    builder.Services.AddHttpClient<IAuthService, KeycloakAuthService>();

    // CCS Level 7 service met resilience pipeline
    builder.Services.Configure<CcsOptions>(config.GetSection(CcsOptions.Section));
    builder.Services.AddHttpClient<ICcsService, CcsService>(client =>
    {
        client.BaseAddress = new Uri(config["Ccs:BaseUrl"]!);
        client.DefaultRequestHeaders.Add("X-Api-Key", config["Ccs:ApiKey"]);
    })
    .AddResilienceHandler("ccs", b => b.AddCcsResiliencePipeline());
}

builder.Services.AddAuthorization();

// Health checks
builder.Services.AddHealthChecks()
    .AddCheck("self", () => HealthCheckResult.Healthy());

if (!useMock)
{
    builder.Services.AddHealthChecks()
        .AddUrlGroup(new Uri($"{config["Ccs:BaseUrl"]}/health"), name: "ccs-level7", tags: ["external"])
        .AddUrlGroup(new Uri($"{config["Keycloak:Authority"]}/.well-known/openid-configuration"),
            name: "keycloak", tags: ["external"]);
}

// Swagger / OpenAPI
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Claeren Policy App BFF",
        Version = "v1",
        Description = useMock
            ? "Claeren polissen-app BFF — MOCK modus (CCS Level 7 gesimuleerd)"
            : "Claeren polissen-app BFF — PRODUCTIE (CCS Level 7 live)"
    });

    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Bearer token. Gebruik: Bearer {token}",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
            },
            Array.Empty<string>()
        }
    });
});

// CORS
var allowedOrigins = config.GetSection("Cors:AllowedOrigins").Get<string[]>()
    ?? ["http://localhost:*"];

builder.Services.AddCors(o =>
    o.AddPolicy("MobileApp", p => p
        .WithOrigins(allowedOrigins)
        .AllowAnyHeader()
        .AllowAnyMethod()));

// Logging
builder.Logging.AddConsole();
if (!builder.Environment.IsDevelopment())
    builder.Logging.AddJsonConsole();

var app = builder.Build();

if (app.Environment.IsDevelopment() || useMock)
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "Claeren Policy App BFF v1");
        c.RoutePrefix = string.Empty;
    });
}

app.UseCors("MobileApp");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapHealthChecks("/health");
app.MapHealthChecks("/health/ready", new()
{
    Predicate = check => check.Tags.Contains("external"),
    ResultStatusCodes =
    {
        [HealthStatus.Healthy] = StatusCodes.Status200OK,
        [HealthStatus.Degraded] = StatusCodes.Status200OK,
        [HealthStatus.Unhealthy] = StatusCodes.Status503ServiceUnavailable,
    }
});

app.Run();
