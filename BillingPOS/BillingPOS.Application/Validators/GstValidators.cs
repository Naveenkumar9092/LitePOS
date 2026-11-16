using BillingPOS.Application.DTOs;
using FluentValidation;

namespace BillingPOS.Application.Validators;

public class CreateTaxValidator : AbstractValidator<CreateTaxDto>
{
    public CreateTaxValidator()
    {
        RuleFor(x => x.TaxName)
            .NotEmpty().WithMessage("Tax name is required.")
            .MaximumLength(100).WithMessage("Tax name must not exceed 100 characters.");

        RuleFor(x => x.RatePercentage)
            .InclusiveBetween(0m, 100m).WithMessage("Tax rate must be between 0% and 100%.");
    }
}

public class UpdateTaxValidator : AbstractValidator<UpdateTaxDto>
{
    public UpdateTaxValidator()
    {
        RuleFor(x => x.TaxName)
            .NotEmpty().WithMessage("Tax name is required.")
            .MaximumLength(100).WithMessage("Tax name must not exceed 100 characters.");

        RuleFor(x => x.RatePercentage)
            .InclusiveBetween(0m, 100m).WithMessage("Tax rate must be between 0% and 100%.");
    }
}

public class CreateHsnSacValidator : AbstractValidator<CreateHsnSacDto>
{
    public CreateHsnSacValidator()
    {
        RuleFor(x => x.Code)
            .NotEmpty().WithMessage("HSN/SAC code is required.")
            .MinimumLength(2).WithMessage("Code must be at least 2 digits.")
            .MaximumLength(20).WithMessage("Code must not exceed 20 characters.");

        RuleFor(x => x.Description)
            .NotEmpty().WithMessage("Description is required.")
            .MaximumLength(300).WithMessage("Description must not exceed 300 characters.");

        RuleFor(x => x.Type)
            .NotEmpty().WithMessage("Type is required.")
            .Must(t => t.Equals("HSN", StringComparison.OrdinalIgnoreCase) || t.Equals("SAC", StringComparison.OrdinalIgnoreCase))
            .WithMessage("Type must be either HSN or SAC.");

        RuleFor(x => x.DefaultGstRate)
            .InclusiveBetween(0m, 100m).WithMessage("Default GST rate must be between 0% and 100%.");
    }
}

public class UpdateGstConfigurationValidator : AbstractValidator<UpdateGstConfigurationDto>
{
    public UpdateGstConfigurationValidator()
    {
        RuleFor(x => x.GSTIN)
            .NotEmpty().WithMessage("GSTIN is required.")
            .Matches(@"^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$")
            .WithMessage("Invalid Indian GSTIN format. Example: 33AAAAA0000A1Z5");

        RuleFor(x => x.LegalName)
            .NotEmpty().WithMessage("Legal business name is required.")
            .MaximumLength(150);

        RuleFor(x => x.TradeName)
            .NotEmpty().WithMessage("Trade name is required.")
            .MaximumLength(150);

        RuleFor(x => x.StateName)
            .NotEmpty().WithMessage("State name is required.");

        RuleFor(x => x.StateCode)
            .NotEmpty().WithMessage("State code is required.")
            .Length(2).WithMessage("State code must be 2 digits (e.g. 33 for TN).");
    }
}

public class CreateCreditNoteValidator : AbstractValidator<CreateCreditNoteDto>
{
    public CreateCreditNoteValidator()
    {
        RuleFor(x => x.InvoiceId)
            .GreaterThan(0).WithMessage("Valid Invoice ID is required.");

        RuleFor(x => x.Reason)
            .NotEmpty().WithMessage("Reason for credit note is required.")
            .MinimumLength(3).WithMessage("Reason must be at least 3 characters.")
            .MaximumLength(300).WithMessage("Reason cannot exceed 300 characters.");

        RuleFor(x => x.NoteType)
            .NotEmpty()
            .Must(t => t.Equals("CreditNote", StringComparison.OrdinalIgnoreCase) || t.Equals("DebitNote", StringComparison.OrdinalIgnoreCase))
            .WithMessage("NoteType must be either CreditNote or DebitNote.");

        RuleFor(x => x.Items)
            .NotEmpty().WithMessage("At least one item must be specified.")
            .Must(items => items != null && items.All(i => i.Quantity > 0))
            .WithMessage("All item quantities must be greater than zero.");
    }
}

