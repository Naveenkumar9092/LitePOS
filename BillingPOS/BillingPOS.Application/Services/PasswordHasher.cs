using System.Security.Cryptography;
using BillingPOS.Application.Interfaces;

namespace BillingPOS.Application.Services;

public class PasswordHasher : IPasswordHasher
{
    private const int SaltSize = 16; // 128 bit
    private const int KeySize = 32;  // 256 bit
    private const int Iterations = 100000;
    private static readonly HashAlgorithmName Algorithm = HashAlgorithmName.SHA256;
    private const char SegmentDelimiter = '$';

    public string HashPassword(string password)
    {
        byte[] salt = RandomNumberGenerator.GetBytes(SaltSize);
        byte[] hash = Rfc2898DeriveBytes.Pbkdf2(
            password,
            salt,
            Iterations,
            Algorithm,
            KeySize
        );

        return string.Join(
            SegmentDelimiter,
            "pbkdf2-sha256",
            Iterations.ToString(),
            Convert.ToBase64String(salt),
            Convert.ToBase64String(hash)
        );
    }

    public bool VerifyPassword(string password, string passwordHash)
    {
        if (string.IsNullOrWhiteSpace(passwordHash)) return false;

        var segments = passwordHash.Split(SegmentDelimiter);
        if (segments.Length != 4) return false;

        if (segments[0] != "pbkdf2-sha256") return false;

        if (!int.TryParse(segments[1], out int iterations)) return false;

        try
        {
            byte[] salt = Convert.FromBase64String(segments[2]);
            byte[] expectedHash = Convert.FromBase64String(segments[3]);

            byte[] actualHash = Rfc2898DeriveBytes.Pbkdf2(
                password,
                salt,
                iterations,
                Algorithm,
                expectedHash.Length
            );

            return CryptographicOperations.FixedTimeEquals(actualHash, expectedHash);
        }
        catch
        {
            return false;
        }
    }
}

