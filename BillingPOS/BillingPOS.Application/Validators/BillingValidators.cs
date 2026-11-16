using BillingPOS.Application.DTOs;
using FluentValidation;

namespace BillingPOS.Application.Validators;

public class CreateInvoiceItemValidator : AbstractValidator<CreateInvoiceItemDto>
{
    public CreateInvoiceItemValidator()
    {
        RuleFor(x => x.ProductId)
            .GreaterThan(0).WithMessage("Product ID must be greater than zero.");

        RuleFor(x => x.Quantity)
            .GreaterThan(0).WithMessage("Quantity must be at least 1.");

        RuleFor(x => x.UnitPrice)
            .GreaterThanOrEqualTo(0).WithMessage("Unit price cannot be negative.");

        RuleFor(x => x.DiscountAmount)
            .GreaterThanOrEqualTo(0).WithMessage("Discount amount cannot be negative.");

        RuleFor(x => x.TaxPercentage)
            .GreaterThanOrEqualTo(0).WithMessage("Tax percentage cannot be negative.")
            .LessThanOrEqualTo(100).WithMessage("Tax percentage cannot exceed 100%.");
    }
}

public class CreateInvoiceValidator : AbstractValidator<CreateInvoiceDto>
{
    public CreateInvoiceValidator()
    {
        RuleFor(x => x.Items)
            .NotEmpty().WithMessage("An invoice must contain at least one item.");

        RuleForEach(x => x.Items).SetValidator(new CreateInvoiceItemValidator());

        RuleFor(x => x.DiscountAmount)
            .GreaterThanOrEqualTo(0).WithMessage("Overall discount amount cannot be negative.");

        RuleFor(x => x.PaidAmount)
            .GreaterThanOrEqualTo(0).WithMessage("Paid amount cannot be negative.");
    }
}

public class HoldBillValidator : AbstractValidator<HoldBillDto>
{
    public HoldBillValidator()
    {
        RuleFor(x => x.Items)
            .NotEmpty().WithMessage("Held bill must contain at least one item.");

        RuleForEach(x => x.Items).SetValidator(new CreateInvoiceItemValidator());

        RuleFor(x => x.DiscountAmount)
            .GreaterThanOrEqualTo(0).WithMessage("Discount amount cannot be negative.");
    }
}

public class CancelBillValidator : AbstractValidator<CancelBillDto>
{
    public CancelBillValidator()
    {
        RuleFor(x => x.Reason)
            .NotEmpty().WithMessage("A cancellation reason is required.")
            .MaximumLength(300).WithMessage("Cancellation reason cannot exceed 300 characters.");
    }
}

