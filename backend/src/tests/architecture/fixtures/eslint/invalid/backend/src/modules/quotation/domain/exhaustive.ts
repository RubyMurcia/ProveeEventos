export function label(status: 'A' | 'B'): string {
  switch (status) {
    case 'A':
      return 'a';
    default:
      return '?';
  }
}
