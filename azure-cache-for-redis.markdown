# Azure Cache for Redis

Tiers:

- Basic: single server, ideal for dev/testing, no SLA;
- Standard: supports two servers (master/slave), 99.99% SLA;
- Premium: persistence, clustering and scale-out, virtual network;

Best practices:

- Redis works best with data that is 100K or less
- Longer keys cause longer lookup times because they're compared byte-by-byte

Transactions:

- Use `MULTI`, `EXEC` to init and commit a transaction
  - If a command is queued with incorrect syntax, the transaction will be automatically discarded;
  - If a command fails, the transaction will complete as normal;
- There is no rollback;
