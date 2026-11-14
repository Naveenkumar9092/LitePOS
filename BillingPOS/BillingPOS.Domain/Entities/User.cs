namespace BillingPOS.Domain.Entities;

public class User : AuditableEntity<long>
{
    public long CompanyId { get; set; }
    public long? ShopId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? MobileNumber { get; set; }
    public string PasswordHash { get; set; } = string.Empty;
    public int RoleId { get; set; }

    // Navigation properties
    public virtual Company Company { get; set; } = null!;
    public virtual Shop? Shop { get; set; }
    public virtual Role Role { get; set; } = null!;
    public virtual ICollection<UserSession> Sessions { get; set; } = new List<UserSession>();
    public virtual ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();
    public virtual ICollection<LoginAuditLog> AuditLogs { get; set; } = new List<LoginAuditLog>();
}

