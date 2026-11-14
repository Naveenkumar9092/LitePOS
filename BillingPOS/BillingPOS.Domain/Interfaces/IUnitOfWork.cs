using BillingPOS.Domain.Entities;

namespace BillingPOS.Domain.Interfaces;

public interface IUnitOfWork : IDisposable, IAsyncDisposable
{
    IRepository<TEntity, TKey> Repository<TEntity, TKey>() where TEntity : BaseEntity<TKey>;
    IRepository<TEntity, long> Repository<TEntity>() where TEntity : BaseEntity<long>;
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
    Task BeginTransactionAsync(CancellationToken cancellationToken = default);
    Task CommitTransactionAsync(CancellationToken cancellationToken = default);
    Task RollbackTransactionAsync(CancellationToken cancellationToken = default);
}

