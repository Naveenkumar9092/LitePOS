using BillingPOS.Application.DTOs;

namespace BillingPOS.Application.Interfaces;

public interface IHardwareService
{
    Task<List<PrinterConfigurationDto>> GetPrintersAsync(CancellationToken cancellationToken = default);
    Task<PrinterConfigurationDto?> GetPrinterByIdAsync(long id, CancellationToken cancellationToken = default);
    Task<PrinterConfigurationDto> GetDefaultPrinterAsync(CancellationToken cancellationToken = default);
    Task<PrinterConfigurationDto> CreatePrinterAsync(CreatePrinterConfigurationDto dto, CancellationToken cancellationToken = default);
    Task<PrinterConfigurationDto> UpdatePrinterAsync(long id, UpdatePrinterConfigurationDto dto, CancellationToken cancellationToken = default);
    Task<bool> DeletePrinterAsync(long id, CancellationToken cancellationToken = default);
    Task<PrinterConfigurationDto> SetDefaultPrinterAsync(long id, CancellationToken cancellationToken = default);
    Task<TestPrintResultDto> GenerateTestPrintAsync(long? printerId = null, CancellationToken cancellationToken = default);
    Task<ReceiptPrintResultDto> GenerateInvoiceReceiptEscPosAsync(long invoiceId, long? printerId = null, CancellationToken cancellationToken = default);
    CashDrawerCommandDto GenerateOpenCashDrawerCommand();
}

