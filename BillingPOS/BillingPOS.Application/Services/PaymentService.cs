using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Entities;
using BillingPOS.Domain.Enums;
using BillingPOS.Domain.Interfaces;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace BillingPOS.Application.Services;

public class PaymentService : IPaymentService
{
    private readonly IRepository<Payment> _paymentRepository;
    private readonly IRepository<Refund> _refundRepository;
    private readonly IRepository<CashRegister> _cashRegisterRepository;
    private readonly IRepository<Invoice> _invoiceRepository;
    private readonly IRepository<Order> _orderRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly IDateTimeService _dateTimeService;
    private readonly IValidator<ProcessPaymentDto> _processPaymentValidator;
    private readonly IValidator<ProcessSplitPaymentDto> _processSplitPaymentValidator;
    private readonly IValidator<ProcessRefundDto> _processRefundValidator;
    private readonly IValidator<OpenCashRegisterDto> _openCashRegisterValidator;
    private readonly IValidator<CloseCashRegisterDto> _closeCashRegisterValidator;
    private readonly ILogger<PaymentService> _logger;

    public PaymentService(
        IRepository<Payment> paymentRepository,
        IRepository<Refund> refundRepository,
        IRepository<CashRegister> cashRegisterRepository,
        IRepository<Invoice> invoiceRepository,
        IRepository<Order> orderRepository,
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        IDateTimeService dateTimeService,
        IValidator<ProcessPaymentDto> processPaymentValidator,
        IValidator<ProcessSplitPaymentDto> processSplitPaymentValidator,
        IValidator<ProcessRefundDto> processRefundValidator,
        IValidator<OpenCashRegisterDto> openCashRegisterValidator,
        IValidator<CloseCashRegisterDto> closeCashRegisterValidator,
        ILogger<PaymentService> logger)
    {
        _paymentRepository = paymentRepository;
        _refundRepository = refundRepository;
        _cashRegisterRepository = cashRegisterRepository;
        _invoiceRepository = invoiceRepository;
        _orderRepository = orderRepository;
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
        _dateTimeService = dateTimeService;
        _processPaymentValidator = processPaymentValidator;
        _processSplitPaymentValidator = processSplitPaymentValidator;
        _processRefundValidator = processRefundValidator;
        _openCashRegisterValidator = openCashRegisterValidator;
        _closeCashRegisterValidator = closeCashRegisterValidator;
        _logger = logger;
    }

    public async Task<ApiResponse<PaymentTransactionDto>> ProcessPaymentAsync(ProcessPaymentDto dto, CancellationToken cancellationToken = default)
    {
        try
        {
            var validation = await _processPaymentValidator.ValidateAsync(dto, cancellationToken);
            if (!validation.IsValid)
            {
                var errors = validation.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<PaymentTransactionDto>.FailureResult("Validation failed.", errors);
            }

            var invoice = await _invoiceRepository.Query()
                .Include(i => i.Payments)
                .Include(i => i.Order)
                .Include(i => i.Customer)
                .FirstOrDefaultAsync(i => i.Id == dto.InvoiceId, cancellationToken);

            if (invoice == null)
            {
                return ApiResponse<PaymentTransactionDto>.FailureResult("Invoice not found.");
            }

            if (invoice.InvoiceStatus == InvoiceStatus.Cancelled)
            {
                return ApiResponse<PaymentTransactionDto>.FailureResult("Cannot accept payment for a cancelled invoice.");
            }

            var remainingBalance = Math.Max(0, invoice.GrandTotal - invoice.PaidAmount);
            if (remainingBalance <= 0)
            {
                return ApiResponse<PaymentTransactionDto>.FailureResult("Invoice is already fully paid.");
            }

            // Cap recorded payment at remaining balance (for Cash, change is given back)
            var actualPaymentAmount = Math.Min(dto.Amount, remainingBalance);

            var payment = new Payment
            {
                PaymentGuid = Guid.NewGuid(),
                InvoiceId = invoice.Id,
                PaymentMode = dto.PaymentMode,
                PaymentModeName = dto.PaymentMode.ToString(),
                Amount = actualPaymentAmount,
                TransactionReference = !string.IsNullOrWhiteSpace(dto.TransactionReference) ? dto.TransactionReference.Trim() : null,
                PaymentStatus = PaymentStatus.Paid,
                CreatedAtUtc = _dateTimeService.UtcNow
            };

            await _paymentRepository.AddAsync(payment, cancellationToken);

            // Update Invoice
            invoice.PaidAmount += actualPaymentAmount;
            invoice.BalanceAmount = Math.Max(0, invoice.GrandTotal - invoice.PaidAmount);
            invoice.PaymentStatus = invoice.BalanceAmount == 0 ? PaymentStatus.Paid : PaymentStatus.PartiallyPaid;
            _invoiceRepository.Update(invoice);

            // Update linked order if fully paid
            if (invoice.PaymentStatus == PaymentStatus.Paid && invoice.Order != null)
            {
                if (invoice.Order.OrderStatus == OrderStatus.New)
                {
                    invoice.Order.OrderStatus = OrderStatus.Confirmed;
                    invoice.Order.UpdatedAtUtc = _dateTimeService.UtcNow;
                    invoice.Order.UpdatedBy = _currentUserService.Username ?? "Cashier";
                    _orderRepository.Update(invoice.Order);
                }
            }

            await _unitOfWork.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Payment of INR {Amount} processed for Invoice {InvoiceNumber} via {Mode}",
                actualPaymentAmount, invoice.InvoiceNumber, dto.PaymentMode);

            var result = MapToPaymentDto(payment, invoice, invoice.Customer);
            return ApiResponse<PaymentTransactionDto>.SuccessResult(result, "Payment processed successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing payment for invoice {InvoiceId}", dto.InvoiceId);
            return ApiResponse<PaymentTransactionDto>.FailureResult("An error occurred while processing the payment.");
        }
    }

    public async Task<ApiResponse<List<PaymentTransactionDto>>> ProcessSplitPaymentAsync(ProcessSplitPaymentDto dto, CancellationToken cancellationToken = default)
    {
        try
        {
            var validation = await _processSplitPaymentValidator.ValidateAsync(dto, cancellationToken);
            if (!validation.IsValid)
            {
                var errors = validation.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<List<PaymentTransactionDto>>.FailureResult("Validation failed.", errors);
            }

            var invoice = await _invoiceRepository.Query()
                .Include(i => i.Payments)
                .Include(i => i.Order)
                .Include(i => i.Customer)
                .FirstOrDefaultAsync(i => i.Id == dto.InvoiceId, cancellationToken);

            if (invoice == null)
            {
                return ApiResponse<List<PaymentTransactionDto>>.FailureResult("Invoice not found.");
            }

            if (invoice.InvoiceStatus == InvoiceStatus.Cancelled)
            {
                return ApiResponse<List<PaymentTransactionDto>>.FailureResult("Cannot accept payment for a cancelled invoice.");
            }

            var remainingBalance = Math.Max(0, invoice.GrandTotal - invoice.PaidAmount);
            var totalSplitAmount = dto.Payments.Sum(p => p.Amount);

            if (totalSplitAmount > remainingBalance)
            {
                return ApiResponse<List<PaymentTransactionDto>>.FailureResult($"Total split amount (₹{totalSplitAmount}) exceeds remaining balance (₹{remainingBalance}).");
            }

            var createdPayments = new List<Payment>();

            foreach (var item in dto.Payments)
            {
                var payment = new Payment
                {
                    PaymentGuid = Guid.NewGuid(),
                    InvoiceId = invoice.Id,
                    PaymentMode = item.PaymentMode,
                    PaymentModeName = item.PaymentMode.ToString(),
                    Amount = item.Amount,
                    TransactionReference = !string.IsNullOrWhiteSpace(item.TransactionReference) ? item.TransactionReference.Trim() : null,
                    PaymentStatus = PaymentStatus.Paid,
                    CreatedAtUtc = _dateTimeService.UtcNow
                };

                await _paymentRepository.AddAsync(payment, cancellationToken);
                createdPayments.Add(payment);
            }

            // Update Invoice
            invoice.PaidAmount += totalSplitAmount;
            invoice.BalanceAmount = Math.Max(0, invoice.GrandTotal - invoice.PaidAmount);
            invoice.PaymentStatus = invoice.BalanceAmount == 0 ? PaymentStatus.Paid : PaymentStatus.PartiallyPaid;
            _invoiceRepository.Update(invoice);

            if (invoice.PaymentStatus == PaymentStatus.Paid && invoice.Order != null)
            {
                if (invoice.Order.OrderStatus == OrderStatus.New)
                {
                    invoice.Order.OrderStatus = OrderStatus.Confirmed;
                    invoice.Order.UpdatedAtUtc = _dateTimeService.UtcNow;
                    invoice.Order.UpdatedBy = _currentUserService.Username ?? "Cashier";
                    _orderRepository.Update(invoice.Order);
                }
            }

            await _unitOfWork.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Split payment of INR {Total} processed across {Count} modes for Invoice {InvoiceNumber}",
                totalSplitAmount, createdPayments.Count, invoice.InvoiceNumber);

            var dtos = createdPayments.Select(p => MapToPaymentDto(p, invoice, invoice.Customer)).ToList();
            return ApiResponse<List<PaymentTransactionDto>>.SuccessResult(dtos, "Split payment processed successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing split payment for invoice {InvoiceId}", dto.InvoiceId);
            return ApiResponse<List<PaymentTransactionDto>>.FailureResult("An error occurred while processing split payment.");
        }
    }

    public async Task<ApiResponse<PaymentTransactionDto>> ProcessRefundAsync(ProcessRefundDto dto, CancellationToken cancellationToken = default)
    {
        try
        {
            var validation = await _processRefundValidator.ValidateAsync(dto, cancellationToken);
            if (!validation.IsValid)
            {
                var errors = validation.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<PaymentTransactionDto>.FailureResult("Validation failed.", errors);
            }

            var invoice = await _invoiceRepository.Query()
                .Include(i => i.Payments)
                .Include(i => i.Customer)
                .FirstOrDefaultAsync(i => i.Id == dto.InvoiceId, cancellationToken);

            if (invoice == null)
            {
                return ApiResponse<PaymentTransactionDto>.FailureResult("Invoice not found.");
            }

            if (invoice.PaidAmount <= 0)
            {
                return ApiResponse<PaymentTransactionDto>.FailureResult("Invoice has no payments to refund.");
            }

            if (dto.Amount > invoice.PaidAmount)
            {
                return ApiResponse<PaymentTransactionDto>.FailureResult($"Refund amount (₹{dto.Amount}) cannot exceed total paid amount (₹{invoice.PaidAmount}).");
            }

            var authorizedBy = !string.IsNullOrWhiteSpace(dto.AuthorizedBy) ? dto.AuthorizedBy.Trim() : (_currentUserService.Username ?? "Admin");
            var processedBy = _currentUserService.Username ?? "Cashier";

            // Record Refund audit entry
            var refund = new Refund
            {
                RefundGuid = Guid.NewGuid(),
                InvoiceId = invoice.Id,
                PaymentId = dto.PaymentId,
                Amount = dto.Amount,
                PaymentMode = PaymentMode.Cash,
                Reason = dto.Reason.Trim(),
                AuthorizedBy = authorizedBy,
                ProcessedBy = processedBy,
                CreatedAtUtc = _dateTimeService.UtcNow
            };
            await _refundRepository.AddAsync(refund, cancellationToken);

            // Record negative payment entry for immutable ledger
            var refundPayment = new Payment
            {
                PaymentGuid = Guid.NewGuid(),
                InvoiceId = invoice.Id,
                PaymentMode = PaymentMode.Cash,
                PaymentModeName = "Refund",
                Amount = -dto.Amount,
                TransactionReference = $"REFUND: {dto.Reason.Trim()} (Auth: {authorizedBy})",
                PaymentStatus = PaymentStatus.Refunded,
                CreatedAtUtc = _dateTimeService.UtcNow
            };
            await _paymentRepository.AddAsync(refundPayment, cancellationToken);

            // Update Invoice
            invoice.PaidAmount -= dto.Amount;
            invoice.BalanceAmount = Math.Max(0, invoice.GrandTotal - invoice.PaidAmount);

            if (invoice.PaidAmount <= 0)
            {
                invoice.PaymentStatus = PaymentStatus.Refunded;
                invoice.InvoiceStatus = InvoiceStatus.Cancelled;
            }
            else
            {
                invoice.PaymentStatus = PaymentStatus.PartiallyPaid;
            }
            _invoiceRepository.Update(invoice);

            await _unitOfWork.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Refund of INR {Amount} processed for Invoice {InvoiceNumber}. Auth: {Auth}",
                dto.Amount, invoice.InvoiceNumber, authorizedBy);

            var result = MapToPaymentDto(refundPayment, invoice, invoice.Customer);
            return ApiResponse<PaymentTransactionDto>.SuccessResult(result, "Refund processed successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing refund for invoice {InvoiceId}", dto.InvoiceId);
            return ApiResponse<PaymentTransactionDto>.FailureResult("An error occurred while processing refund.");
        }
    }

    public async Task<ApiResponse<PagedPaymentsResultDto>> GetPaymentsAsync(PaymentFilterDto filter, CancellationToken cancellationToken = default)
    {
        try
        {
            var query = _paymentRepository.Query()
                .Include(p => p.Invoice)
                .ThenInclude(i => i.Customer)
                .AsNoTracking();

            if (filter.InvoiceId.HasValue)
            {
                query = query.Where(p => p.InvoiceId == filter.InvoiceId.Value);
            }

            if (filter.PaymentMode.HasValue)
            {
                query = query.Where(p => p.PaymentMode == filter.PaymentMode.Value);
            }

            if (filter.PaymentStatus.HasValue)
            {
                query = query.Where(p => p.PaymentStatus == filter.PaymentStatus.Value);
            }

            if (filter.FromDate.HasValue)
            {
                query = query.Where(p => p.CreatedAtUtc >= filter.FromDate.Value);
            }

            if (filter.ToDate.HasValue)
            {
                query = query.Where(p => p.CreatedAtUtc <= filter.ToDate.Value);
            }

            if (!string.IsNullOrWhiteSpace(filter.SearchTerm))
            {
                var term = filter.SearchTerm.Trim().ToLower();
                query = query.Where(p => p.Invoice.InvoiceNumber.ToLower().Contains(term)
                    || (p.TransactionReference != null && p.TransactionReference.ToLower().Contains(term))
                    || (p.Invoice.Customer != null && p.Invoice.Customer.CustomerName.ToLower().Contains(term)));
            }

            var totalCount = await query.CountAsync(cancellationToken);

            var page = filter.Page > 0 ? filter.Page : 1;
            var pageSize = filter.PageSize > 0 ? filter.PageSize : 20;

            var payments = await query
                .OrderByDescending(p => p.CreatedAtUtc)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

            var dtos = payments.Select(p => MapToPaymentDto(p, p.Invoice, p.Invoice.Customer)).ToList();

            var result = new PagedPaymentsResultDto
            {
                Items = dtos,
                TotalCount = totalCount,
                PageNumber = page,
                PageSize = pageSize
            };

            return ApiResponse<PagedPaymentsResultDto>.SuccessResult(result, "Payments retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving payments.");
            return ApiResponse<PagedPaymentsResultDto>.FailureResult("An error occurred while retrieving payments.");
        }
    }

    public async Task<ApiResponse<PaymentTransactionDto>> GetPaymentByIdAsync(long id, CancellationToken cancellationToken = default)
    {
        try
        {
            var payment = await _paymentRepository.Query()
                .Include(p => p.Invoice)
                .ThenInclude(i => i.Customer)
                .FirstOrDefaultAsync(p => p.Id == id, cancellationToken);

            if (payment == null)
            {
                return ApiResponse<PaymentTransactionDto>.FailureResult("Payment not found.");
            }

            var dto = MapToPaymentDto(payment, payment.Invoice, payment.Invoice.Customer);
            return ApiResponse<PaymentTransactionDto>.SuccessResult(dto, "Payment retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving payment {Id}", id);
            return ApiResponse<PaymentTransactionDto>.FailureResult("An error occurred while retrieving the payment.");
        }
    }

    public async Task<ApiResponse<PaymentReconciliationDto>> GetPaymentReconciliationAsync(DateTime? date = null, CancellationToken cancellationToken = default)
    {
        try
        {
            var targetDate = (date?.Date ?? _dateTimeService.UtcNow.Date);
            var nextDate = targetDate.AddDays(1);

            var payments = await _paymentRepository.Query()
                .Where(p => p.CreatedAtUtc >= targetDate && p.CreatedAtUtc < nextDate)
                .ToListAsync(cancellationToken);

            var cashCollected = payments.Where(p => p.PaymentMode == PaymentMode.Cash && p.Amount > 0).Sum(p => p.Amount);
            var upiCollected = payments.Where(p => p.PaymentMode == PaymentMode.UPI && p.Amount > 0).Sum(p => p.Amount);
            var cardCollected = payments.Where(p => p.PaymentMode == PaymentMode.Card && p.Amount > 0).Sum(p => p.Amount);
            var totalRefunds = Math.Abs(payments.Where(p => p.Amount < 0 || p.PaymentStatus == PaymentStatus.Refunded).Sum(p => p.Amount));
            var netCollected = cashCollected + upiCollected + cardCollected - totalRefunds;
            var totalTransactions = payments.Count(p => p.Amount > 0);

            // Active or latest register session
            var session = await _cashRegisterRepository.Query()
                .Where(c => c.OpeningTimeUtc >= targetDate && c.OpeningTimeUtc < nextDate)
                .OrderByDescending(c => c.OpeningTimeUtc)
                .FirstOrDefaultAsync(cancellationToken);

            decimal openingFloat = session?.OpeningFloat ?? 0;
            bool isRegisterOpen = session?.IsOpen ?? false;
            decimal? actualCashInDrawer = session?.ActualCash;
            decimal expectedCashInDrawer = openingFloat + cashCollected - totalRefunds;
            decimal? cashDifference = actualCashInDrawer.HasValue ? actualCashInDrawer.Value - expectedCashInDrawer : null;

            var dto = new PaymentReconciliationDto
            {
                Date = targetDate,
                OpeningFloat = openingFloat,
                CashCollected = cashCollected,
                UpiCollected = upiCollected,
                CardCollected = cardCollected,
                TotalRefunds = totalRefunds,
                NetCollected = netCollected,
                TotalTransactions = totalTransactions,
                ExpectedCashInDrawer = expectedCashInDrawer,
                ActualCashInDrawer = actualCashInDrawer,
                CashDifference = cashDifference,
                IsRegisterOpen = isRegisterOpen,
                CurrentSessionGuid = session?.SessionGuid.ToString()
            };

            return ApiResponse<PaymentReconciliationDto>.SuccessResult(dto, "Reconciliation summary generated successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating payment reconciliation.");
            return ApiResponse<PaymentReconciliationDto>.FailureResult("An error occurred while generating payment reconciliation.");
        }
    }

    public async Task<ApiResponse<CashRegisterSessionDto>> OpenCashRegisterAsync(OpenCashRegisterDto dto, CancellationToken cancellationToken = default)
    {
        try
        {
            var validation = await _openCashRegisterValidator.ValidateAsync(dto, cancellationToken);
            if (!validation.IsValid)
            {
                var errors = validation.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<CashRegisterSessionDto>.FailureResult("Validation failed.", errors);
            }

            var openSession = await _cashRegisterRepository.Query()
                .FirstOrDefaultAsync(c => c.IsOpen, cancellationToken);

            if (openSession != null)
            {
                return ApiResponse<CashRegisterSessionDto>.FailureResult("A cash register session is already open.");
            }

            var cashierUsername = _currentUserService.Username ?? "Cashier";
            var cashierId = _currentUserService.UserId ?? 1;
            var deviceId = !string.IsNullOrWhiteSpace(dto.DeviceId) ? dto.DeviceId.Trim() : "POS-TERMINAL-01";

            var register = new CashRegister
            {
                SessionGuid = Guid.NewGuid(),
                ShopId = 1,
                CashierId = cashierId,
                CashierUsername = cashierUsername,
                DeviceId = deviceId,
                OpeningFloat = dto.OpeningFloat,
                OpeningTimeUtc = _dateTimeService.UtcNow,
                OpeningNotes = dto.Notes,
                IsOpen = true,
                CreatedAtUtc = _dateTimeService.UtcNow
            };

            await _cashRegisterRepository.AddAsync(register, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Cash register opened by {Cashier} with opening float INR {Float}", cashierUsername, dto.OpeningFloat);

            var result = MapToSessionDto(register);
            return ApiResponse<CashRegisterSessionDto>.SuccessResult(result, "Cash register opened successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error opening cash register.");
            return ApiResponse<CashRegisterSessionDto>.FailureResult("An error occurred while opening the cash register.");
        }
    }

    public async Task<ApiResponse<CashRegisterSessionDto>> CloseCashRegisterAsync(CloseCashRegisterDto dto, CancellationToken cancellationToken = default)
    {
        try
        {
            var validation = await _closeCashRegisterValidator.ValidateAsync(dto, cancellationToken);
            if (!validation.IsValid)
            {
                var errors = validation.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<CashRegisterSessionDto>.FailureResult("Validation failed.", errors);
            }

            var session = await _cashRegisterRepository.Query()
                .FirstOrDefaultAsync(c => c.IsOpen, cancellationToken);

            if (session == null)
            {
                return ApiResponse<CashRegisterSessionDto>.FailureResult("No open cash register session found.");
            }

            // Calculate cash collected since session opened
            var payments = await _paymentRepository.Query()
                .Where(p => p.CreatedAtUtc >= session.OpeningTimeUtc)
                .ToListAsync(cancellationToken);

            var cashCollected = payments.Where(p => p.PaymentMode == PaymentMode.Cash && p.Amount > 0).Sum(p => p.Amount);
            var cashRefunds = Math.Abs(payments.Where(p => p.Amount < 0).Sum(p => p.Amount));
            var expectedCash = session.OpeningFloat + cashCollected - cashRefunds;
            var discrepancy = dto.ActualCash - expectedCash;

            session.ClosingTimeUtc = _dateTimeService.UtcNow;
            session.ActualCash = dto.ActualCash;
            session.ExpectedCash = expectedCash;
            session.Discrepancy = discrepancy;
            session.ClosingNotes = dto.Notes;
            session.IsOpen = false;

            _cashRegisterRepository.Update(session);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Cash register closed. Actual: INR {Actual}, Expected: INR {Expected}, Discrepancy: INR {Discrepancy}",
                dto.ActualCash, expectedCash, discrepancy);

            var result = MapToSessionDto(session);
            return ApiResponse<CashRegisterSessionDto>.SuccessResult(result, "Cash register closed successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error closing cash register.");
            return ApiResponse<CashRegisterSessionDto>.FailureResult("An error occurred while closing the cash register.");
        }
    }

    private static PaymentTransactionDto MapToPaymentDto(Payment payment, Invoice invoice, Customer? customer = null)
    {
        return new PaymentTransactionDto
        {
            Id = payment.Id,
            PaymentGuid = payment.PaymentGuid,
            InvoiceId = payment.InvoiceId,
            InvoiceNumber = invoice.InvoiceNumber,
            PaymentMode = payment.PaymentMode,
            PaymentModeName = payment.PaymentModeName,
            Amount = payment.Amount,
            TransactionReference = payment.TransactionReference,
            PaymentStatus = payment.PaymentStatus,
            CreatedAtUtc = payment.CreatedAtUtc,
            CashierUsername = invoice.CashierId > 0 ? "Cashier" : null,
            CustomerName = customer?.CustomerName ?? invoice.Customer?.CustomerName
        };
    }

    private static CashRegisterSessionDto MapToSessionDto(CashRegister register)
    {
        return new CashRegisterSessionDto
        {
            Id = register.Id,
            SessionGuid = register.SessionGuid,
            CashierUsername = register.CashierUsername,
            DeviceId = register.DeviceId,
            OpeningFloat = register.OpeningFloat,
            OpeningTimeUtc = register.OpeningTimeUtc,
            OpeningNotes = register.OpeningNotes,
            ClosingTimeUtc = register.ClosingTimeUtc,
            ActualCash = register.ActualCash,
            ExpectedCash = register.ExpectedCash,
            Discrepancy = register.Discrepancy,
            ClosingNotes = register.ClosingNotes,
            IsOpen = register.IsOpen
        };
    }
}
