using System.Text.RegularExpressions;
using BillingPOS.Application.DTOs;
using FluentValidation;

namespace BillingPOS.Application.Validators;

public class CreateUserValidator : AbstractValidator<CreateUserDto>
{
    private static readonly Regex PhoneRegex = new(@"^[6-9]\d{9}$", RegexOptions.Compiled);
    private static readonly Regex UsernameRegex = new(@"^[a-zA-Z0-9_\-\.]{3,50}$", RegexOptions.Compiled);

    public CreateUserValidator()
    {
        RuleFor(x => x.FullName)
            .NotEmpty().WithMessage("Full Name is required.")
            .MaximumLength(150).WithMessage("Full Name cannot exceed 150 characters.");

        RuleFor(x => x.Username)
            .NotEmpty().WithMessage("Username is required.")
            .Length(3, 50).WithMessage("Username must be between 3 and 50 characters.")
            .Matches(UsernameRegex).WithMessage("Username can only contain letters, numbers, underscores, dots, and hyphens.");

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Password is required.")
            .MinimumLength(6).WithMessage("Password must be at least 6 characters long.");

        RuleFor(x => x.Email)
            .EmailAddress().When(x => !string.IsNullOrWhiteSpace(x.Email))
            .WithMessage("A valid email address is required.");

        RuleFor(x => x.MobileNumber)
            .Matches(PhoneRegex).When(x => !string.IsNullOrWhiteSpace(x.MobileNumber))
            .WithMessage("Mobile Number must be a valid 10-digit Indian mobile number.");

        RuleFor(x => x.RoleId)
            .InclusiveBetween(1, 3).WithMessage("Invalid Role. Role must be SAdmin (1), Admin (2), or Cashier (3).");
    }
}

public class UpdateUserValidator : AbstractValidator<UpdateUserDto>
{
    private static readonly Regex PhoneRegex = new(@"^[6-9]\d{9}$", RegexOptions.Compiled);

    public UpdateUserValidator()
    {
        RuleFor(x => x.FullName)
            .NotEmpty().WithMessage("Full Name is required.")
            .MaximumLength(150).WithMessage("Full Name cannot exceed 150 characters.");

        RuleFor(x => x.Email)
            .EmailAddress().When(x => !string.IsNullOrWhiteSpace(x.Email))
            .WithMessage("A valid email address is required.");

        RuleFor(x => x.MobileNumber)
            .Matches(PhoneRegex).When(x => !string.IsNullOrWhiteSpace(x.MobileNumber))
            .WithMessage("Mobile Number must be a valid 10-digit Indian mobile number.");

        RuleFor(x => x.RoleId)
            .InclusiveBetween(1, 3).WithMessage("Invalid Role. Role must be SAdmin (1), Admin (2), or Cashier (3).");
    }
}

