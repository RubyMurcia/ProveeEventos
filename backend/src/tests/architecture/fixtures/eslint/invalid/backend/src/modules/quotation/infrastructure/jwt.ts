export const x = (jwt: { decode(t: string): string }, t: string): string => jwt.decode(t);
