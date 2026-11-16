using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Entities;
using BillingPOS.Domain.Enums;
using BillingPOS.Domain.Interfaces;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace BillingPOS.Application.Services;

public class OrderService : IOrderService
{
    private readonly IRepository<Order> _orderRepository;
    private readonly IRepository<OrderDetail> _orderDetailRepository;
    private readonly IRepository<Product> _productRepository;
    private readonly IRepository<Customer> _customerRepository;
    private readonly IRepository<Invoice> _invoiceRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly IDateTimeService _dateTimeService;
    private readonly IValidator<CreateOrderDto> _createOrderValidator;
    private readonly IValidator<UpdateOrderStatusDto> _updateOrderStatusValidator;
    private readonly IValidator<CancelOrderDto> _cancelOrderValidator;
    private readonly ILogger<OrderService> _logger;

    public OrderService(
        IRepository<Order> orderRepository,
        IRepository<OrderDetail> orderDetailRepository,
        IRepository<Product> productRepository,
        IRepository<Customer> customerRepository,
        IRepository<Invoice> invoiceRepository,
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        IDateTimeService dateTimeService,
        IValidator<CreateOrderDto> createOrderValidator,
        IValidator<UpdateOrderStatusDto> updateOrderStatusValidator,
        IValidator<CancelOrderDto> cancelOrderValidator,
        ILogger<OrderService> logger)
    {
        _orderRepository = orderRepository;
        _orderDetailRepository = orderDetailRepository;
        _productRepository = productRepository;
        _customerRepository = customerRepository;
        _invoiceRepository = invoiceRepository;
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
        _dateTimeService = dateTimeService;
        _createOrderValidator = createOrderValidator;
        _updateOrderStatusValidator = updateOrderStatusValidator;
        _cancelOrderValidator = cancelOrderValidator;
        _logger = logger;
    }

    public async Task<ApiResponse<OrderDto>> CreateOrderAsync(CreateOrderDto dto, CancellationToken cancellationToken = default)
    {
        try
        {
            var validation = await _createOrderValidator.ValidateAsync(dto, cancellationToken);
            if (!validation.IsValid)
            {
                var errors = validation.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<OrderDto>.FailureResult("Validation failed.", errors);
            }

            Customer? customer = null;
            if (dto.CustomerId.HasValue && dto.CustomerId.Value > 0)
            {
                customer = await _customerRepository.GetByIdAsync(dto.CustomerId.Value, cancellationToken);
                if (customer == null)
                {
                    return ApiResponse<OrderDto>.FailureResult($"Customer with ID {dto.CustomerId.Value} was not found.");
                }
            }

            var productIds = dto.Items.Select(i => i.ProductId).Distinct().ToList();
            var products = await _productRepository.Query()
                .Where(p => productIds.Contains(p.Id))
                .ToDictionaryAsync(p => p.Id, cancellationToken);

            foreach (var item in dto.Items)
            {
                if (!products.TryGetValue(item.ProductId, out var product))
                {
                    return ApiResponse<OrderDto>.FailureResult($"Product with ID {item.ProductId} was not found.");
                }

                if (!product.IsAvailable || !product.IsActive)
                {
                    return ApiResponse<OrderDto>.FailureResult($"Product '{product.ProductName}' is currently unavailable.");
                }
            }

            // Generate order number
            var today = _dateTimeService.UtcNow.Date;
            var todayCount = await _orderRepository.Query()
                .CountAsync(o => o.CreatedAtUtc >= today, cancellationToken);
            var orderNumber = $"ORD-{_dateTimeService.UtcNow:yyyyMMdd}-{(todayCount + 1):D4}";

            decimal subTotal = 0;
            decimal totalLineDiscounts = 0;
            decimal totalTax = 0;

            var orderDetails = new List<OrderDetail>();

            foreach (var itemDto in dto.Items)
            {
                var product = products[itemDto.ProductId];
                var unitPrice = itemDto.UnitPrice > 0 ? itemDto.UnitPrice : product.SellingPrice;
                var lineSubTotal = Math.Round(itemDto.Quantity * unitPrice, 2);
                var lineDiscount = Math.Round(itemDto.DiscountAmount, 2);
                var lineTaxable = Math.Max(0, lineSubTotal - lineDiscount);
                var taxPercentage = itemDto.TaxPercentage > 0 ? itemDto.TaxPercentage : product.TaxPercentage;
                var lineTax = Math.Round(lineTaxable * (taxPercentage / 100m), 2);
                var lineTotal = lineTaxable + lineTax;

                subTotal += lineSubTotal;
                totalLineDiscounts += lineDiscount;
                totalTax += lineTax;

                var detail = new OrderDetail
                {
                    ProductId = product.Id,
                    ProductNameSnapshot = !string.IsNullOrWhiteSpace(itemDto.ProductNameSnapshot)
                        ? itemDto.ProductNameSnapshot.Trim()
                        : product.ProductName,
                    UnitPrice = unitPrice,
                    Quantity = itemDto.Quantity,
                    DiscountAmount = lineDiscount,
                    TaxPercentage = taxPercentage,
                    TaxAmount = lineTax,
                    LineTotal = lineTotal
                };

                orderDetails.Add(detail);
            }

            var discountAmount = dto.DiscountAmount > 0 ? dto.DiscountAmount : totalLineDiscounts;
            var taxableAmount = Math.Max(0, subTotal - discountAmount);
            var grandTotal = Math.Round(taxableAmount + totalTax, 2);

            var cashierUsername = _currentUserService.Username ?? "Cashier";

            var order = new Order
            {
                OrderGuid = Guid.NewGuid(),
                OrderNumber = orderNumber,
                CustomerId = customer?.Id,
                OrderType = dto.OrderType,
                OrderStatus = OrderStatus.New,
                SubTotal = subTotal,
                DiscountAmount = discountAmount,
                TaxAmount = totalTax,
                GrandTotal = grandTotal,
                CashierUsername = cashierUsername,
                CreatedAtUtc = _dateTimeService.UtcNow,
                CreatedBy = cashierUsername,
                IsActive = true,
                Details = orderDetails
            };

            await _orderRepository.AddAsync(order, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Order {OrderNumber} created successfully by {Cashier}", orderNumber, cashierUsername);

            var result = MapToOrderDto(order, customer);
            return ApiResponse<OrderDto>.SuccessResult(result, "Order created successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating order.");
            return ApiResponse<OrderDto>.FailureResult("An error occurred while creating the order.");
        }
    }

    public async Task<ApiResponse<PagedOrdersResultDto>> GetOrdersAsync(OrderFilterDto filter, CancellationToken cancellationToken = default)
    {
        try
        {
            var query = _orderRepository.Query()
                .Include(o => o.Customer)
                .Include(o => o.Details)
                .Include(o => o.Invoice)
                .AsNoTracking();

            if (filter.Status.HasValue)
            {
                query = query.Where(o => o.OrderStatus == filter.Status.Value);
            }

            if (filter.Type.HasValue)
            {
                query = query.Where(o => o.OrderType == filter.Type.Value);
            }

            if (filter.FromDate.HasValue)
            {
                query = query.Where(o => o.CreatedAtUtc >= filter.FromDate.Value);
            }

            if (filter.ToDate.HasValue)
            {
                query = query.Where(o => o.CreatedAtUtc <= filter.ToDate.Value);
            }

            if (!string.IsNullOrWhiteSpace(filter.SearchTerm))
            {
                var term = filter.SearchTerm.Trim().ToLower();
                query = query.Where(o => o.OrderNumber.ToLower().Contains(term)
                    || (o.Customer != null && o.Customer.CustomerName.ToLower().Contains(term))
                    || (o.Customer != null && o.Customer.MobileNumber.Contains(term))
                    || o.CashierUsername.ToLower().Contains(term));
            }

            var totalCount = await query.CountAsync(cancellationToken);

            var page = filter.Page > 0 ? filter.Page : 1;
            var pageSize = filter.PageSize > 0 ? filter.PageSize : 20;

            var orders = await query
                .OrderByDescending(o => o.CreatedAtUtc)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

            var dtos = orders.Select(o => MapToOrderDto(o, o.Customer, o.Invoice)).ToList();

            var result = new PagedOrdersResultDto
            {
                Items = dtos,
                TotalCount = totalCount,
                PageNumber = page,
                PageSize = pageSize
            };

            return ApiResponse<PagedOrdersResultDto>.SuccessResult(result, "Orders retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving orders.");
            return ApiResponse<PagedOrdersResultDto>.FailureResult("An error occurred while retrieving orders.");
        }
    }

    public async Task<ApiResponse<OrderDto>> GetOrderByIdAsync(long id, CancellationToken cancellationToken = default)
    {
        try
        {
            var order = await _orderRepository.Query()
                .Include(o => o.Customer)
                .Include(o => o.Details)
                .Include(o => o.Invoice)
                .FirstOrDefaultAsync(o => o.Id == id, cancellationToken);

            if (order == null)
            {
                return ApiResponse<OrderDto>.FailureResult("Order not found.");
            }

            var dto = MapToOrderDto(order, order.Customer, order.Invoice);
            return ApiResponse<OrderDto>.SuccessResult(dto, "Order retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving order {Id}.", id);
            return ApiResponse<OrderDto>.FailureResult("An error occurred while retrieving the order.");
        }
    }

    public async Task<ApiResponse<OrderDto>> UpdateOrderStatusAsync(long id, UpdateOrderStatusDto dto, CancellationToken cancellationToken = default)
    {
        try
        {
            var validation = await _updateOrderStatusValidator.ValidateAsync(dto, cancellationToken);
            if (!validation.IsValid)
            {
                var errors = validation.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<OrderDto>.FailureResult("Validation failed.", errors);
            }

            var order = await _orderRepository.Query()
                .Include(o => o.Customer)
                .Include(o => o.Details)
                .Include(o => o.Invoice)
                .FirstOrDefaultAsync(o => o.Id == id, cancellationToken);

            if (order == null)
            {
                return ApiResponse<OrderDto>.FailureResult("Order not found.");
            }

            if (order.OrderStatus == OrderStatus.Completed)
            {
                return ApiResponse<OrderDto>.FailureResult("Cannot change the status of an already completed order.");
            }

            if (order.OrderStatus == OrderStatus.Cancelled)
            {
                return ApiResponse<OrderDto>.FailureResult("Cannot change the status of a cancelled order.");
            }

            // Validate status transitions
            if (dto.NewStatus == order.OrderStatus)
            {
                return ApiResponse<OrderDto>.SuccessResult(MapToOrderDto(order, order.Customer, order.Invoice), "Order status remains unchanged.");
            }

            bool isValidTransition = order.OrderStatus switch
            {
                OrderStatus.New => dto.NewStatus is OrderStatus.Confirmed or OrderStatus.Cancelled,
                OrderStatus.Confirmed => dto.NewStatus is OrderStatus.Preparing or OrderStatus.Ready or OrderStatus.Completed or OrderStatus.Cancelled,
                OrderStatus.Preparing => dto.NewStatus is OrderStatus.Ready or OrderStatus.Completed or OrderStatus.Cancelled,
                OrderStatus.Ready => dto.NewStatus is OrderStatus.Completed or OrderStatus.Cancelled,
                _ => false
            };

            if (!isValidTransition)
            {
                return ApiResponse<OrderDto>.FailureResult($"Invalid status transition from {order.OrderStatus} to {dto.NewStatus}.");
            }

            var username = _currentUserService.Username ?? "Cashier";

            order.OrderStatus = dto.NewStatus;
            order.UpdatedAtUtc = _dateTimeService.UtcNow;
            order.UpdatedBy = !string.IsNullOrWhiteSpace(dto.Notes)
                ? $"{username}: {dto.Notes.Trim()}"
                : username;

            _orderRepository.Update(order);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Order {OrderNumber} updated to {NewStatus} by {User}", order.OrderNumber, dto.NewStatus, username);

            var result = MapToOrderDto(order, order.Customer, order.Invoice);
            return ApiResponse<OrderDto>.SuccessResult(result, $"Order status updated to {dto.NewStatus}.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating order status for {Id}.", id);
            return ApiResponse<OrderDto>.FailureResult("An error occurred while updating order status.");
        }
    }

    public async Task<ApiResponse<OrderDto>> CancelOrderAsync(long id, CancelOrderDto dto, CancellationToken cancellationToken = default)
    {
        try
        {
            var validation = await _cancelOrderValidator.ValidateAsync(dto, cancellationToken);
            if (!validation.IsValid)
            {
                var errors = validation.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<OrderDto>.FailureResult("Validation failed.", errors);
            }

            var order = await _orderRepository.Query()
                .Include(o => o.Customer)
                .Include(o => o.Details)
                .Include(o => o.Invoice)
                .FirstOrDefaultAsync(o => o.Id == id, cancellationToken);

            if (order == null)
            {
                return ApiResponse<OrderDto>.FailureResult("Order not found.");
            }

            if (order.OrderStatus == OrderStatus.Completed)
            {
                return ApiResponse<OrderDto>.FailureResult("Cannot cancel an order that has already been completed.");
            }

            if (order.OrderStatus == OrderStatus.Cancelled)
            {
                return ApiResponse<OrderDto>.FailureResult("Order is already cancelled.");
            }

            var username = _currentUserService.Username ?? "Cashier";

            order.OrderStatus = OrderStatus.Cancelled;
            order.UpdatedAtUtc = _dateTimeService.UtcNow;
            order.UpdatedBy = $"{username}: {dto.Reason.Trim()}";

            _orderRepository.Update(order);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Order {OrderNumber} cancelled by {User}. Reason: {Reason}", order.OrderNumber, username, dto.Reason);

            var result = MapToOrderDto(order, order.Customer, order.Invoice);
            return ApiResponse<OrderDto>.SuccessResult(result, "Order cancelled successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error cancelling order {Id}.", id);
            return ApiResponse<OrderDto>.FailureResult("An error occurred while cancelling the order.");
        }
    }

    public async Task<ApiResponse<PagedOrdersResultDto>> GetOrderHistoryAsync(OrderFilterDto filter, CancellationToken cancellationToken = default)
    {
        try
        {
            var query = _orderRepository.Query()
                .Include(o => o.Customer)
                .Include(o => o.Details)
                .Include(o => o.Invoice)
                .Where(o => o.OrderStatus == OrderStatus.Completed || o.OrderStatus == OrderStatus.Cancelled)
                .AsNoTracking();

            if (filter.Status.HasValue)
            {
                query = query.Where(o => o.OrderStatus == filter.Status.Value);
            }

            if (filter.Type.HasValue)
            {
                query = query.Where(o => o.OrderType == filter.Type.Value);
            }

            if (filter.FromDate.HasValue)
            {
                query = query.Where(o => o.CreatedAtUtc >= filter.FromDate.Value);
            }

            if (filter.ToDate.HasValue)
            {
                query = query.Where(o => o.CreatedAtUtc <= filter.ToDate.Value);
            }

            if (!string.IsNullOrWhiteSpace(filter.SearchTerm))
            {
                var term = filter.SearchTerm.Trim().ToLower();
                query = query.Where(o => o.OrderNumber.ToLower().Contains(term)
                    || (o.Customer != null && o.Customer.CustomerName.ToLower().Contains(term))
                    || (o.Customer != null && o.Customer.MobileNumber.Contains(term))
                    || o.CashierUsername.ToLower().Contains(term));
            }

            var totalCount = await query.CountAsync(cancellationToken);

            var page = filter.Page > 0 ? filter.Page : 1;
            var pageSize = filter.PageSize > 0 ? filter.PageSize : 20;

            var orders = await query
                .OrderByDescending(o => o.CreatedAtUtc)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

            var dtos = orders.Select(o => MapToOrderDto(o, o.Customer, o.Invoice)).ToList();

            var result = new PagedOrdersResultDto
            {
                Items = dtos,
                TotalCount = totalCount,
                PageNumber = page,
                PageSize = pageSize
            };

            return ApiResponse<PagedOrdersResultDto>.SuccessResult(result, "Order history retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving order history.");
            return ApiResponse<PagedOrdersResultDto>.FailureResult("An error occurred while retrieving order history.");
        }
    }

    private static OrderDto MapToOrderDto(Order order, Customer? customer = null, Invoice? invoice = null)
    {
        return new OrderDto
        {
            Id = order.Id,
            OrderGuid = order.OrderGuid,
            OrderNumber = order.OrderNumber,
            CustomerId = order.CustomerId,
            CustomerName = customer?.CustomerName ?? order.Customer?.CustomerName,
            CustomerMobile = customer?.MobileNumber ?? order.Customer?.MobileNumber,
            OrderType = order.OrderType,
            OrderStatus = order.OrderStatus,
            SubTotal = order.SubTotal,
            DiscountAmount = order.DiscountAmount,
            TaxAmount = order.TaxAmount,
            GrandTotal = order.GrandTotal,
            CashierUsername = order.CashierUsername,
            CreatedAtUtc = order.CreatedAtUtc,
            UpdatedAtUtc = order.UpdatedAtUtc,
            CreatedBy = order.CreatedBy,
            UpdatedBy = order.UpdatedBy,
            InvoiceId = invoice?.Id ?? order.Invoice?.Id,
            InvoiceNumber = invoice?.InvoiceNumber ?? order.Invoice?.InvoiceNumber,
            Details = order.Details.Select(d => new OrderDetailDto
            {
                Id = d.Id,
                OrderId = d.OrderId,
                ProductId = d.ProductId,
                ProductNameSnapshot = d.ProductNameSnapshot,
                UnitPrice = d.UnitPrice,
                Quantity = d.Quantity,
                DiscountAmount = d.DiscountAmount,
                TaxPercentage = d.TaxPercentage,
                TaxAmount = d.TaxAmount,
                LineTotal = d.LineTotal
            }).ToList()
        };
    }
}

