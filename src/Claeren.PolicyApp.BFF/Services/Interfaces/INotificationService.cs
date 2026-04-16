namespace Claeren.PolicyApp.BFF.Services.Interfaces;

public interface INotificationService
{
    Task SendPushAsync(string userId, string titel, string bericht, NotificatieType type, string? referentieId = null);
}

public enum NotificatieType
{
    NieuwDocument,
    NaverrekenUitvraag,
    OfferteOndertekenen,
    SluitverklaringInvullen,
    ClaimUpdate
}
