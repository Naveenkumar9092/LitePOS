using BillingPOS.Application.DTOs;
using BillingPOS.Domain.Enums;
using FluentValidation;

namespace BillingPOS.Application.Validators;

public class CreatePrinterConfigurationValidator : AbstractValidator<CreatePrinterConfigurationDto>
{
    public CreatePrinterConfigurationValidator()
    {
        RuleFor(x => x.PrinterName)
            .NotEmpty().WithMessage("Printer name is required.")
            .MaximumLength(100).WithMessage("Printer name cannot exceed 100 characters.");

        When(x => x.ConnectionType == PrinterConnectionType.Network, () =>
        {
            RuleFor(x => x.IpAddress)
                .NotEmpty().WithMessage("IP address is required for network printers.");

            RuleFor(x => x.Port)
                .InclusiveBetween(1, 65535).WithMessage("Port must be between 1 and 65535.");
        });

        When(x => x.ConnectionType == PrinterConnectionType.USB, () =>
        {
            RuleFor(x => x.UsbDeviceName)
                .NotEmpty().WithMessage("USB device name is required for USB printers.");
        });

        When(x => x.ConnectionType == PrinterConnectionType.Bluetooth, () =>
        {
            RuleFor(x => x.BluetoothMacAddress)
                .NotEmpty().WithMessage("Bluetooth MAC address is required for Bluetooth printers.");
        });

        RuleFor(x => x.PrintCopies)
            .InclusiveBetween(1, 5).WithMessage("Print copies must be between 1 and 5.");
    }
}

public class UpdatePrinterConfigurationValidator : AbstractValidator<UpdatePrinterConfigurationDto>
{
    public UpdatePrinterConfigurationValidator()
    {
        RuleFor(x => x.PrinterName)
            .NotEmpty().WithMessage("Printer name is required.")
            .MaximumLength(100).WithMessage("Printer name cannot exceed 100 characters.");

        When(x => x.ConnectionType == PrinterConnectionType.Network, () =>
        {
            RuleFor(x => x.IpAddress)
                .NotEmpty().WithMessage("IP address is required for network printers.");

            RuleFor(x => x.Port)
                .InclusiveBetween(1, 65535).WithMessage("Port must be between 1 and 65535.");
        });

        When(x => x.ConnectionType == PrinterConnectionType.USB, () =>
        {
            RuleFor(x => x.UsbDeviceName)
                .NotEmpty().WithMessage("USB device name is required for USB printers.");
        });

        When(x => x.ConnectionType == PrinterConnectionType.Bluetooth, () =>
        {
            RuleFor(x => x.BluetoothMacAddress)
                .NotEmpty().WithMessage("Bluetooth MAC address is required for Bluetooth printers.");
        });

        RuleFor(x => x.PrintCopies)
            .InclusiveBetween(1, 5).WithMessage("Print copies must be between 1 and 5.");
    }
}

