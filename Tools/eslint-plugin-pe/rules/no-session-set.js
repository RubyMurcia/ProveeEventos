// ADR-DATA-008 R4: nada que sobreviva a la transacción en una conexión del pooler.
const FORBIDDEN = [
  /(^|;)\s*SET\s+(?!LOCAL\b|TRANSACTION\b|CONSTRAINTS\b)[\w.]+\s*(=|\bTO\b)/i,
  /set_config\s*\([^)]*,\s*false\s*\)/i,
  /(^|;)\s*(LISTEN|UNLISTEN|NOTIFY)\s+\w+/,
  /pg_(try_)?advisory_lock(_shared)?\s*\(/i,
  /CREATE\s+(GLOBAL\s+|LOCAL\s+)?TEMP(ORARY)?\s+TABLE/i,
];
export default {
  meta: {
    type: 'problem',
    schema: [],
    messages: {
      session:
        'Prohibido el estado de sesión (SET sin LOCAL, set_config false, LISTEN/NOTIFY, bloqueo consultivo de sesión o tabla temporal).',
    },
  },
  create(context) {
    const check = (node, text) => {
      if (FORBIDDEN.some((pattern) => pattern.test(text)))
        context.report({ node, messageId: 'session' });
    };
    return {
      Literal(node) {
        if (typeof node.value === 'string') check(node, node.value);
      },
      TemplateLiteral(node) {
        check(node, node.quasis.map((quasi) => quasi.value.raw).join('?'));
      },
    };
  },
};
