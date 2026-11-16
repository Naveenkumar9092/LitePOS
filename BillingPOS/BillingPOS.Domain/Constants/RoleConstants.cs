namespace BillingPOS.Domain.Constants;

public static class RoleConstants
{
    public const string SAdmin = "SAdmin";
    public const string Admin = "Admin";
    public const string Cashier = "Cashier";

    public static readonly string[] AllRoles = [SAdmin, Admin, Cashier];
}

