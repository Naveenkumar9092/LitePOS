namespace BillingPOS.Application.Exceptions;

public class AppException : Exception
{
    public int StatusCode { get; set; } = 400;
    public List<string> Errors { get; set; } = [];

    public AppException(string message, int statusCode = 400) : base(message)
    {
        StatusCode = statusCode;
        Errors = [message];
    }

    public AppException(string message, IEnumerable<string> errors, int statusCode = 400) : base(message)
    {
        StatusCode = statusCode;
        Errors = errors.ToList();
    }
}

public class NotFoundException : AppException
{
    public NotFoundException(string message) : base(message, 404)
    {
    }

    public NotFoundException(string entityName, object key) 
        : base($"{entityName} with key '{key}' was not found.", 404)
    {
    }
}

public class ValidationException : AppException
{
    public ValidationException(string message, IEnumerable<string> errors) 
        : base(message, errors, 400)
    {
    }

    public ValidationException(IEnumerable<string> errors) 
        : base("One or more validation failures have occurred.", errors, 400)
    {
    }
}

public class UnauthorizedException : AppException
{
    public UnauthorizedException(string message = "You are not authorized to access this resource.") 
        : base(message, 401)
    {
    }
}

public class ForbiddenException : AppException
{
    public ForbiddenException(string message = "You do not have permission to perform this action.") 
        : base(message, 403)
    {
    }
}

