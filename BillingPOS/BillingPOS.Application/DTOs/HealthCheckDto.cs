namespace BillingPOS.Application.DTOs;

public class HealthCheckDto
{
    public string Status { get; set; } = "Healthy";
    public string Environment { get; set; } = string.Empty;
    public string Version { get; set; } = string.Empty;
    public DateTime ServerTimeUtc { get; set; }
    public bool DatabaseConnected { get; set; }
    public string DatabaseProvider { get; set; } = string.Empty;
}

