using BillingPOS.Application.DTOs;
using FluentValidation;

namespace BillingPOS.Application.Validators;

public class CreateCustomerValidator : AbstractValidator<CreateCustomerDto>
{
    public CreateCustomerValidator()
    {
        RuleFor(x => x.CustomerName)
            .NotEmpty().WithMessage("Customer name is required.")
            .MaximumLength(150).WithMessage("Customer name must not exceed 150 characters.");

        RuleFor(x => x.MobileNumber)
            .NotEmpty().WithMessage("Mobile number is required.")
            .Matches(@"^[6-9]\d{9}$").WithMessage("Invalid Indian mobile number. Must be 10 digits starting with 6-9.");

        When(x => !string.IsNullOrWhiteSpace(x.WhatsAppNumber), () =>
        {
            RuleFor(x => x.WhatsAppNumber!)
                .Matches(@"^[6-9]\d{9}$").WithMessage("Invalid WhatsApp number. Must be 10 digits starting with 6-9.");
        });

        When(x => !string.IsNullOrWhiteSpace(x.Email), () =>
        {
            RuleFor(x => x.Email!)
                .EmailAddress().WithMessage("Invalid email format.")
                .MaximumLength(150).WithMessage("Email must not exceed 150 characters.");
        });

        When(x => !string.IsNullOrWhiteSpace(x.GSTIN), () =>
        {
            RuleFor(x => x.GSTIN!)
                .Matches(@"^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$")
                .WithMessage("Invalid Indian GSTIN format. Example: 33AAAAA0000A1Z5");
        });

        When(x => !string.IsNullOrWhiteSpace(x.Address), () =>
        {
            RuleFor(x => x.Address!)
                .MaximumLength(300).WithMessage("Address must not exceed 300 characters.");
        });
    }
}

public class UpdateCustomerValidator : AbstractValidator<UpdateCustomerDto>
{
    public UpdateCustomerValidator()
    {
        RuleFor(x => x.CustomerName)
            .NotEmpty().WithMessage("Customer name is required.")
            .MaximumLength(150).WithMessage("Customer name must not exceed 150 characters.");

        RuleFor(x => x.MobileNumber)
            .NotEmpty().WithMessage("Mobile number is required.")
            .Matches(@"^[6-9]\d{9}$").WithMessage("Invalid Indian mobile number. Must be 10 digits starting with 6-9.");

        When(x => !string.IsNullOrWhiteSpace(x.WhatsAppNumber), () =>
        {
            RuleFor(x => x.WhatsAppNumber!)
                .Matches(@"^[6-9]\d{9}$").WithMessage("Invalid WhatsApp number. Must be 10 digits starting with 6-9.");
        });

        When(x => !string.IsNullOrWhiteSpace(x.Email), () =>
        {
            RuleFor(x => x.Email!)
                .EmailAddress().WithMessage("Invalid email format.")
                .MaximumLength(150).WithMessage("Email must not exceed 150 characters.");
        });

        When(x => !string.IsNullOrWhiteSpace(x.GSTIN), () =>
        {
            RuleFor(x => x.GSTIN!)
                .Matches(@"^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$")
                .WithMessage("Invalid Indian GSTIN format. Example: 33AAAAA0000A1Z5");
        });

        When(x => !string.IsNullOrWhiteSpace(x.Address), () =>
        {
            RuleFor(x => x.Address!)
                .MaximumLength(300).WithMessage("Address must not exceed 300 characters.");
        });
    }
}

