// Reglas propias de Capa 1 (ADR §6.1). Ruta protegida (ADR-GOV-002).
import apiClientServerOnly from './rules/api-client-server-only.js';
import capacityWriteOwner from './rules/capacity-write-owner.js';
import deleteAllowlist from './rules/delete-allowlist.js';
import noIoInTransaction from './rules/no-io-in-transaction.js';
import noSessionSet from './rules/no-session-set.js';
import noSuppressionComments from './rules/no-suppression-comments.js';
import prismaModelOwnership from './rules/prisma-model-ownership.js';
import tenantWrapper from './rules/tenant-wrapper.js';
import validateRequest from './rules/validate-request.js';

export default {
  meta: { name: 'eslint-plugin-pe', version: '1.0.0' },
  rules: {
    'api-client-server-only': apiClientServerOnly,
    'capacity-write-owner': capacityWriteOwner,
    'delete-allowlist': deleteAllowlist,
    'no-io-in-transaction': noIoInTransaction,
    'no-session-set': noSessionSet,
    'no-suppression-comments': noSuppressionComments,
    'prisma-model-ownership': prismaModelOwnership,
    'tenant-wrapper': tenantWrapper,
    'validate-request': validateRequest,
  },
};
