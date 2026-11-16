namespace BillingPOS.Application.DTOs;

public class ApiResponse<T>
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public T? Data { get; set; }
    public List<string>? Errors { get; set; }

    public static ApiResponse<T> SuccessResult(T data, string message = "Operation completed successfully")
    {
        return new ApiResponse<T>
        {
            Success = true,
            Message = message,
            Data = data,
            Errors = null
        };
    }

    public static ApiResponse<T> Ok(T data, string message = "Operation completed successfully") => SuccessResult(data, message);

    public static ApiResponse<T> FailureResult(string message, List<string>? errors = null, T? defaultData = default)
    {
        return new ApiResponse<T>
        {
            Success = false,
            Message = message,
            Data = defaultData,
            Errors = errors ?? [message]
        };
    }

    public static ApiResponse<T> Fail(string message, List<string>? errors = null, T? defaultData = default) => FailureResult(message, errors, defaultData);
}

public class ApiResponse : ApiResponse<object>
{
    public static ApiResponse SuccessResult(string message = "Operation completed successfully")
    {
        return new ApiResponse
        {
            Success = true,
            Message = message,
            Data = null,
            Errors = null
        };
    }

    public static ApiResponse Ok(string message = "Operation completed successfully") => SuccessResult(message);

    public static ApiResponse FailureResult(string message, List<string>? errors = null)
    {
        return new ApiResponse
        {
            Success = false,
            Message = message,
            Data = null,
            Errors = errors ?? [message]
        };
    }

    public static ApiResponse Fail(string message, List<string>? errors = null) => FailureResult(message, errors);
}
