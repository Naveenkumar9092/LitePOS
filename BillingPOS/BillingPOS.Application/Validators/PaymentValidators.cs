using BillingPOS.Application.DTOs;
using BillingPOS.Domain.Enums;
using FluentValidation;

namespace BillingPOS.Application.Validators;

public class ProcessPaymentValidator : AbstractValidator<ProcessPaymentDto>
{
    public ProcessPaymentValidator()
    {
        RuleFor(x => x.InvoiceId)
            .GreaterThan(0).WithMessage("Invoice ID must be greater than zero.");

        RuleFor(x => x.Amount)
            .GreaterThan(0).WithMessage("Payment amount must be greater than zero.");

        RuleFor(x => x.PaymentMode)
            .IsInEnum().WithMessage("Invalid payment mode specified.");

        RuleFor(x => x.TransactionReference)
            .NotEmpty().WithMessage("Transaction reference is required for UPI payments.")
            .When(x => x.PaymentMode == PaymentMode.UPI);

        RuleFor(x => x.TransactionReference)
            .NotEmpty().WithMessage("Transaction reference / authorization code is required for Card payments.")
            .When(x => x.PaymentMode == PaymentMode.Card);
    }
}

public class SplitPaymentItemValidator : AbstractValidator<SplitPaymentItemDto>
{
    public SplitPaymentItemValidator()
    {
        RuleFor(x => x.Amount)
            .GreaterThan(0).WithMessage("Split item amount must be greater than zero.");

        RuleFor(x => x.PaymentMode)
            .IsInEnum().WithMessage("Invalid payment mode specified.");

        RuleFor(x => x.TransactionReference)
            .NotEmpty().WithMessage("Transaction reference is required for UPI payments.")
            .When(x => x.PaymentMode == PaymentMode.UPI);

        RuleFor(x => x.TransactionReference)
            .NotEmpty().WithMessage("Transaction reference is required for Card payments.")
            .When(x => x.PaymentMode == PaymentMode.Card);
    }
}

public class ProcessSplitPaymentValidator : AbstractValidator<ProcessSplitPaymentDto>
{
    public ProcessSplitPaymentValidator()
    {
        RuleFor(x => x.InvoiceId)
            .GreaterThan(0).WithMessage("Invoice ID must be greater than zero.");

        RuleFor(x => x.Payments)
            .NotEmpty().WithMessage("Split payments list cannot be empty.")
            .Must(list => list != null && list.Count >= 2)
            .WithMessage("Split payments require at least two payment components.");

        RuleForEach(x => x.Payments).SetValidator(new SplitPaymentItemValidator());
    }
}

public class ProcessRefundValidator : AbstractValidator<ProcessRefundDto>
{
    public ProcessRefundValidator()
    {
        RuleFor(x => x.InvoiceId)
            .GreaterThan(0).WithMessage("Invoice ID must be greater than zero.");

        RuleFor(x => x.Amount)
            .GreaterThan(0).WithMessage("Refund amount must be greater than zero.");

        RuleFor(x => x.Reason)
            .NotEmpty().WithMessage("Refund reason is mandatory.")
            .MaximumLength(300).WithMessage("Refund reason cannot exceed 300 characters.");
    }
}

public class OpenCashRegisterValidator : AbstractValidator<OpenCashRegisterDto>
{
    public OpenCashRegisterValidator()
    {
        RuleFor(x => x.OpeningFloat)
            .GreaterThanOrEqualTo(0).WithMessage("Opening float cannot be negative.");

        RuleFor(x => x.Notes)
            .MaximumLength(500).WithMessage("Notes cannot exceed 500 characters.")
            .When(x => !string.IsNullOrEmpty(x.Notes));
    }
}

public class CloseCashRegisterValidator : AbstractValidator<CloseCashRegisterDto>
{
    public CloseCashRegisterValidator()
    {
        RuleFor(x => x.ActualCash)
            .GreaterThanOrEqualTo(0).WithMessage("Actual cash cannot be negative.");

        RuleFor(x => x.Notes)
            .MaximumLength(500).WithMessage("Notes cannot exceed 500 characters.")
            .When(x => !string.IsNullOrEmpty(x.Notes));
    }
}

