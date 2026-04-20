using Claeren.PolicyApp.BFF.Infrastructure.Auth;
using Claeren.PolicyApp.BFF.Services.Implementations;
using Claeren.PolicyApp.BFF.Services.Interfaces;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;

var builder = WebApplication.CreateBuilder(args);
var config = builder.Configuration;
var useMock = config.GetValue<bool>("Features:MockCcs");

builder.Services.AddControllers()
    .AddJsonOptions(o => o.JsonSerializerOptions.Converters.Add(
        new System.Text.Json.Serialization.JsonStringEnumConverter()));

if (useMock)
{
    var secret = Encoding.UTF8.GetBytes(config["Jwt:Secret"]!);
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
                IssuerSigningKey = new SymmetricSecurityKey(secret),
            };
        });
    builder.Services.AddScoped<IAuthService, AuthService>();
    builder.Services.AddScoped<ICcsService, MockCcsService>();
}
else
{
    builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddJwtBearer(o =>
        {
            o.Authority = config["Keycloak:Authority"];
            o.Audience = config["Keycloak:ClientId"];
            o.RequireHttpsMetadata = true;
        });

    builder.Services.Configure<KeycloakOptions>(config.GetSection(KeycloakOptions.Section));
    builder.Services.AddHttpClient<IAuthService, KeycloakAuthService>();

    builder.Services.Configure<CcsOptions>(config.GetSection(CcsOptions.Section));
    builder.Services.AddHttpClient<ICcsService, CcsService>(client =>
    {
        client.BaseAddress = new Uri(config["Ccs:BaseUrl"]!);
        client.DefaultRequestHeaders.Add("X-Api-Key", config["Ccs:ApiKey"]);
    });
}

builder.Services.AddAuthorization();
builder.Services.AddHealthChecks();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Claeren Policy App BFF",
        Version = "v1",
        Description = useMock ? "MOCK modus" : "PRODUCTIE"
    });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Bearer token",
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

builder.Services.AddCors(o =>
{
    if (useMock)
    {
        // Mock/test modus: sta alle origins toe
        o.AddPolicy("MobileApp", p => p
            .AllowAnyOrigin()
            .AllowAnyHeader()
            .AllowAnyMethod());
    }
    else
    {
        var allowedOrigins = config.GetSection("Cors:AllowedOrigins").Get<string[]>()
            ?? ["http://localhost:*"];
        o.AddPolicy("MobileApp", p => p
            .WithOrigins(allowedOrigins)
            .AllowAnyHeader()
            .AllowAnyMethod());
    }
});

builder.Logging.AddConsole();

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "Claeren Policy App BFF v1");
    c.RoutePrefix = string.Empty;
});

// Altijd CORS-headers meesturen (mock-modus = testomgeving)
app.Use(async (ctx, next) =>
{
    ctx.Response.Headers["Access-Control-Allow-Origin"] = "*";
    ctx.Response.Headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS";
    ctx.Response.Headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization";
    if (ctx.Request.Method == "OPTIONS")
    {
        ctx.Response.StatusCode = 200;
        await ctx.Response.CompleteAsync();
        return;
    }
    await next();
});

app.UseCors("MobileApp");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapHealthChecks("/health");

app.Run();
