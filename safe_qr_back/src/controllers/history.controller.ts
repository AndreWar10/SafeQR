import type { FastifyReply, FastifyRequest } from 'fastify';

import {
  historyIdParamsSchema,
  historyListQuerySchema,
  historyPostBodySchema,
} from '../schemas/history.schema.js';
import { bearerAuthErrorMessage, bearerAuthStatusCode } from '../lib/bearer-auth.js';
import type { HistoryService } from '../services/history.service.js';
import type { UserIdentityPort } from '../services/user-identity.port.js';
import {
  notFoundError,
  unauthorizedError,
  validationError,
} from '../views/error-response.view.js';
import {
  toHistoryListResponseJson,
  toHistoryUpsertResponseJson,
} from '../views/history-response.view.js';

type HistoryControllerDeps = {
  service: HistoryService;
  userIdentity: UserIdentityPort;
};

export class HistoryController {
  constructor(private readonly deps: HistoryControllerDeps) {}

  postHistory = async (req: FastifyRequest, reply: FastifyReply) => {
    const requestId = req.id;
    const parsed = historyPostBodySchema.safeParse(req.body);
    if (!parsed.success) {
      return reply.status(400).send(
        validationError(requestId, 'Corpo inválido.', parsed.error.flatten()),
      );
    }

    const identity = await this.deps.userIdentity.resolveBearerUid(req);
    if (!identity.ok) {
      return reply
        .status(bearerAuthStatusCode(identity.reason))
        .send(unauthorizedError(requestId, bearerAuthErrorMessage(identity.reason)));
    }

    const { item } = parsed.data;
    if (item.content.length > 2000) {
      return reply.status(413).send({
        error: 'PAYLOAD_TOO_LARGE',
        message: 'Conteúdo excede o limite de 2000 caracteres.',
        requestId,
      });
    }

    req.log.info(
      {
        event: 'history_upsert',
        idUser: identity.idUser,
        itemId: item.id,
        itemType: item.type,
      },
      'Histórico upsert solicitado',
    );

    const result = await this.deps.service.upsert(identity.idUser, item);
    return reply.status(201).send(toHistoryUpsertResponseJson(result));
  };

  getHistory = async (req: FastifyRequest, reply: FastifyReply) => {
    const requestId = req.id;
    const identity = await this.deps.userIdentity.resolveBearerUid(req);
    if (!identity.ok) {
      return reply
        .status(bearerAuthStatusCode(identity.reason))
        .send(unauthorizedError(requestId, bearerAuthErrorMessage(identity.reason)));
    }

    const queryParsed = historyListQuerySchema.safeParse(req.query);
    if (!queryParsed.success) {
      return reply.status(400).send(
        validationError(requestId, 'Query inválida.', queryParsed.error.flatten()),
      );
    }

    const result = await this.deps.service.list(identity.idUser, queryParsed.data);
    return reply.send(toHistoryListResponseJson(result));
  };

  deleteHistoryById = async (req: FastifyRequest, reply: FastifyReply) => {
    const requestId = req.id;
    const identity = await this.deps.userIdentity.resolveBearerUid(req);
    if (!identity.ok) {
      return reply
        .status(bearerAuthStatusCode(identity.reason))
        .send(unauthorizedError(requestId, bearerAuthErrorMessage(identity.reason)));
    }

    const paramsParsed = historyIdParamsSchema.safeParse(req.params);
    if (!paramsParsed.success) {
      return reply.status(400).send(
        validationError(requestId, 'Parâmetro inválido.', paramsParsed.error.flatten()),
      );
    }

    const itemId = paramsParsed.data.id;
    try {
      const deleted = await this.deps.service.deleteById(identity.idUser, itemId);
      if (!deleted) {
        return reply.status(404).send(notFoundError(requestId, 'Item de histórico não encontrado.'));
      }
    } catch (err) {
      req.log.error(
        { err, event: 'history_delete_failed', idUser: identity.idUser, itemId },
        'Falha ao apagar item de histórico',
      );
      throw err;
    }

    return reply.code(204).send();
  };

  clearHistory = async (req: FastifyRequest, reply: FastifyReply) => {
    const requestId = req.id;
    const identity = await this.deps.userIdentity.resolveBearerUid(req);
    if (!identity.ok) {
      return reply
        .status(bearerAuthStatusCode(identity.reason))
        .send(unauthorizedError(requestId, bearerAuthErrorMessage(identity.reason)));
    }

    try {
      await this.deps.service.clear(identity.idUser);
    } catch (err) {
      req.log.error(
        { err, event: 'history_clear_failed', idUser: identity.idUser },
        'Falha ao limpar histórico',
      );
      throw err;
    }
    return reply.code(204).send();
  };
}
