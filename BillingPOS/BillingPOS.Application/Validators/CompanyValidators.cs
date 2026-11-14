using System.Text.RegularExpressions;
using BillingPOS.Application.DTOs;
using FluentValidation;

namespace BillingPOS.Application.Validators;

public class CompanySetupValidator : AbstractValidator<CompanySetupRequestDto>
{
    private static readonly Regex GstinRegex = new(@"^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$", RegexOptions.Compiled);
    private static readonly Regex PhoneRegex = new(@"^[6-9]\d{9}$", RegexOptions.Compiled);
    private static readonly Regex PincodeRegex = new(@"^\d{6}$", RegexOptions.Compiled);

    public CompanySetupValidator()
    {
        RuleFor(x => x.CompanyName)
            .NotEmpty().WithMessage("Company Name is required.")
            .MaximumLength(150).WithMessage("Company Name cannot exceed 150 characters.");

        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required.")
            .EmailAddress().WithMessage("A valid email address is required.");

        RuleFor(x => x.MobileNumber)
            .NotEmpty().WithMessage("Mobile Number is required.")
            .Matches(PhoneRegex).WithMessage("Please enter a valid 10-digit Indian mobile number.");

        RuleFor(x => x.GSTIN)
            .Matches(GstinRegex).When(x => !string.IsNullOrWhiteSpace(x.GSTIN))
            .WithMessage("Invalid GSTIN format. Example: 22AAAAA0000A1Z5");

        RuleFor(x => x.ShopName)
            .NotEmpty().WithMessage("Shop Name is required.")
            .MaximumLength(150).WithMessage("Shop Name cannot exceed 150 characters.");

        RuleFor(x => x.AddressLine1)
            .NotEmpty().WithMessage("Shop Address is required.")
            .MaximumLength(250).WithMessage("Address cannot exceed 250 characters.");

        RuleFor(x => x.City)
            .NotEmpty().WithMessage("City is required.");

        RuleFor(x => x.State)
            .NotEmpty().WithMessage("State is required.");

        RuleFor(x => x.Pincode)
            .NotEmpty().WithMessage("Pincode is required.")
            .Matches(PincodeRegex).WithMessage("Pincode must be 6 digits.");

        RuleFor(x => x.ContactNumber)
            .NotEmpty().WithMessage("Shop Contact Number is required.")
            .Matches(PhoneRegex).WithMessage("Shop Contact Number must be a valid 10-digit mobile number.");

        RuleFor(x => x.ShopEmail)
            .NotEmpty().WithMessage("Shop Email is required.")
            .EmailAddress().WithMessage("A valid shop email address is required.");

        RuleFor(x => x.CurrencyCode)
            .NotEmpty().WithMessage("Currency Code is required.")
            .Length(3).WithMessage("Currency Code must be 3 characters (e.g. INR).");
    }
}

public class UpdateCompanyProfileValidator : AbstractValidator<UpdateCompanyProfileDto>
{
    private static readonly Regex GstinRegex = new(@"^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$", RegexOptions.Compiled);
    private static readonly Regex PhoneRegex = new(@"^[6-9]\d{9}$", RegexOptions.Compiled);

    public UpdateCompanyProfileValidator()
    {
        RuleFor(x => x.CompanyName)
            .NotEmpty().WithMessage("Company Name is required.")
            .MaximumLength(150).WithMessage("Company Name cannot exceed 150 characters.");

        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required.")
            .EmailAddress().WithMessage("A valid email address is required.");

        RuleFor(x => x.MobileNumber)
            .NotEmpty().WithMessage("Mobile Number is required.")
            .Matches(PhoneRegex).WithMessage("Please enter a valid 10-digit Indian mobile number.");

        RuleFor(x => x.GSTIN)
            .Matches(GstinRegex).When(x => !string.IsNullOrWhiteSpace(x.GSTIN))
            .WithMessage("Invalid GSTIN format. Example: 22AAAAA0000A1Z5");
    }
}

public class UpdateShopConfigurationValidator : AbstractValidator<UpdateShopConfigurationDto>
{
    private static readonly Regex PhoneRegex = new(@"^[6-9]\d{9}$", RegexOptions.Compiled);
    private static readonly Regex PincodeRegex = new(@"^\d{6}$", RegexOptions.Compiled);

    public UpdateShopConfigurationValidator()
    {
        RuleFor(x => x.ShopName)
            .NotEmpty().WithMessage("Shop Name is required.")
            .MaximumLength(150).WithMessage("Shop Name cannot exceed 150 characters.");

        RuleFor(x => x.AddressLine1)
            .NotEmpty().WithMessage("Shop Address is required.");

        RuleFor(x => x.City)
            .NotEmpty().WithMessage("City is required.");

        RuleFor(x => x.State)
            .NotEmpty().WithMessage("State is required.");

        RuleFor(x => x.Pincode)
            .NotEmpty().WithMessage("Pincode is required.")
            .Matches(PincodeRegex).WithMessage("Pincode must be 6 digits.");

        RuleFor(x => x.ContactNumber)
            .NotEmpty().WithMessage("Shop Contact Number is required.")
            .Matches(PhoneRegex).WithMessage("Shop Contact Number must be a valid 10-digit mobile number.");

        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Shop Email is required.")
            .EmailAddress().WithMessage("A valid shop email address is required.");
    }
}

