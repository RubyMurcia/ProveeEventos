export interface Delegate {
  findMany(): Promise<void>;
  update(args: { data: Record<string, number> }): Promise<void>;
  delete(): Promise<void>;
  deleteMany(): Promise<void>;
  create(): Promise<void>;
  createMany(): Promise<void>;
}
export interface Db {
  booking: Delegate;
  auditLog: Delegate;
  quotation: Delegate;
  quotationItemOption: Delegate;
  providerDailyCapacity: Delegate;
  $transaction<T>(work: (tx: Db) => Promise<T>): Promise<T>;
  $queryRaw(strings: TemplateStringsArray, ...values: unknown[]): Promise<void>;
  $queryRawUnsafe(sql: string): Promise<void>;
}
