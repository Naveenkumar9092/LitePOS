using BillingPOS.Application.DTOs;
using FluentValidation;

namespace BillingPOS.Application.Validators;

public class CreateProductValidator : AbstractValidator<CreateProductDto>
{
    public CreateProductValidator()
    {
        RuleFor(x => x.ProductName)
            .NotEmpty().WithMessage("Product name is mandatory.")
            .MaximumLength(100).WithMessage("Product name cannot exceed 100 characters.");

        RuleFor(x => x.CategoryId)
            .GreaterThan(0).WithMessage("A valid Category must be selected.");

        RuleFor(x => x.SellingPrice)
            .GreaterThan(0).WithMessage("Selling price must be greater than zero. Products must have a valid selling price.");

        RuleFor(x => x.TaxPercentage)
            .InclusiveBetween(0, 100).WithMessage("Tax percentage must be between 0% and 100%.");

        RuleFor(x => x.HSNCode)
            .MaximumLength(20).WithMessage("HSN Code cannot exceed 20 characters.")
            .When(x => !string.IsNullOrEmpty(x.HSNCode));
    }
}

public class UpdateProductValidator : AbstractValidator<UpdateProductDto>
{
    public UpdateProductValidator()
    {
        RuleFor(x => x.ProductName)
            .NotEmpty().WithMessage("Product name is mandatory.")
            .MaximumLength(100).WithMessage("Product name cannot exceed 100 characters.");

        RuleFor(x => x.CategoryId)
            .GreaterThan(0).WithMessage("A valid Category must be selected.");

        RuleFor(x => x.SellingPrice)
            .GreaterThan(0).WithMessage("Selling price must be greater than zero.");

        RuleFor(x => x.TaxPercentage)
            .InclusiveBetween(0, 100).WithMessage("Tax percentage must be between 0% and 100%.");

        RuleFor(x => x.HSNCode)
            .MaximumLength(20).WithMessage("HSN Code cannot exceed 20 characters.")
            .When(x => !string.IsNullOrEmpty(x.HSNCode));
    }
}

