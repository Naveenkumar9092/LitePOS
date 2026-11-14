using BillingPOS.Application.DTOs;
using FluentValidation;

namespace BillingPOS.Application.Validators;

public class SendInvoiceNotificationDtoValidator : AbstractValidator<SendInvoiceNotificationDto>
{
    public SendInvoiceNotificationDtoValidator()
    {
        RuleFor(x => x.InvoiceId)
            .GreaterThan(0)
            .WithMessage("Valid Invoice ID is required.");

        RuleFor(x => x.Channel)
            .IsInEnum()
            .WithMessage("Valid notification channel (Email, WhatsApp, SMS) is required.");

        When(x => !string.IsNullOrEmpty(x.RecipientOverride), () =>
        {
            RuleFor(x => x.RecipientOverride)
                .MaximumLength(150)
                .WithMessage("Recipient address cannot exceed 150 characters.");
        });
    }
}

public class UpdateShopPreferenceDtoValidator : AbstractValidator<UpdateShopPreferenceDto>
{
    public UpdateShopPreferenceDtoValidator()
    {
        RuleFor(x => x.DefaultGstRate)
            .InclusiveBetween(0.0m, 100.0m)
            .WithMessage("Default GST rate must be between 0% and 100%.");

        When(x => !string.IsNullOrEmpty(x.ReceiptHeaderCustom), () =>
        {
            RuleFor(x => x.ReceiptHeaderCustom)
                .MaximumLength(300)
                .WithMessage("Custom receipt header cannot exceed 300 characters.");
        });

        When(x => !string.IsNullOrEmpty(x.ReceiptFooterCustom), () =>
        {
            RuleFor(x => x.ReceiptFooterCustom)
                .MaximumLength(300)
                .WithMessage("Custom receipt footer cannot exceed 300 characters.");
        });
    }
}

