import { z } from 'zod';
import { validated } from '../../../shared/http/validate-request.js';
export const schema = z.strictObject({ id: z.string() });
export const x = validated('x');
