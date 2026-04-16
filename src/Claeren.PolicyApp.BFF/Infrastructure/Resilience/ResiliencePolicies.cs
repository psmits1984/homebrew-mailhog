using Microsoft.Extensions.Http.Resilience;

namespace Claeren.PolicyApp.BFF.Infrastructure.Resilience;

public static class ResiliencePolicies
{
    // Standaard Polly pipeline: 3x retry met exponential backoff + circuit breaker.
    public static IHttpResiliencePipelineBuilder AddCcsResiliencePipeline(
        this IHttpResiliencePipelineBuilder builder) =>
        builder.Configure(pipeline =>
        {
            pipeline.AddRetry(new HttpRetryStrategyOptions
            {
                MaxRetryAttempts = 3,
                BackoffType = DelayBackoffType.Exponential,
                Delay = TimeSpan.FromMilliseconds(300),
                ShouldHandle = args => ValueTask.FromResult(
                    args.Outcome.Exception is not null ||
                    (args.Outcome.Result?.StatusCode >= System.Net.HttpStatusCode.InternalServerError))
            });

            pipeline.AddCircuitBreaker(new HttpCircuitBreakerStrategyOptions
            {
                SamplingDuration = TimeSpan.FromSeconds(30),
                MinimumThroughput = 5,
                FailureRatio = 0.5,
                BreakDuration = TimeSpan.FromSeconds(15),
            });

            pipeline.AddTimeout(TimeSpan.FromSeconds(10));
        });
}
