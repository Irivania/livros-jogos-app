# Arquitetura técnica do Livros-Jogos

## 1. Decisão de plataforma

O baseline é **Flutter + Dart**: uma base de UI para Android (prioridade Play Store), iOS e desktop, com um domínio compartilhado e integração nativa isolada. Firebase é o exemplo de backend adotado neste starter por oferecer Auth, App Check, Analytics e regras de acesso; Supabase pode substituir os adaptadores sem alterar o motor.

## 2. Modularização e Clean Architecture

```text
lib/
  core/
    errors/                 Falhas tipadas compartilhadas
    security/               Armazenamento seguro e políticas locais
  features/
    auth/
      data/                 FirebaseAuthRepository
      domain/               AuthRepository e entidades
      presentation/
    story_engine/
      data/                 Loader/cache/validador JSON (próximo módulo)
      domain/               Story, escolhas, estado e StoryEngine
      presentation/         Controller reativo para a UI
assets/stories/<story-id>/
  story.json
  cover.webp
  scene-*.webp
```

Regra de dependência: `presentation -> domain <- data`. O domínio não importa Flutter, Firebase, HTTP ou banco. Cada feature pode virar um pacote Dart/Flutter quando o produto crescer.

### Fluxo de uma nova história

1. CMS ou pipeline editorial produz um pacote `story.json` + mídias.
2. CI valida JSON Schema, IDs únicos, referências de nós/provas e ausência de ciclos proibidos.
3. O pacote é assinado e publicado em CDN/versionamento imutável.
4. O catálogo baixa apenas `manifest.json`; cenas e mídia são carregadas sob demanda.
5. O parser transforma o JSON em entidades de domínio. O motor só conhece o contrato, não o título.

Não coloque regras editoriais em `if (storyId == ...)`. Se uma história exigir uma regra nova, ela deve ser representada no schema/versionamento ou em um `RuleEvaluator` extensível.

## 3. Contrato de conteúdo

O exemplo executável está em [assets/stories/black-rain/story.json](../assets/stories/black-rain/story.json). Cada escolha suporta:

- `requires`: provas necessárias;
- `addEvidence`/`removeEvidence`: mutações atômicas do Murder Board;
- `keyCost`: custo para reexecução;
- `nextNodeId`: próximo nó, mutuamente exclusivo com `endingId`;
- `endingId`: final terminal, mutuamente exclusivo com `nextNodeId`.

Um contrato de produção deve adicionar `schemaVersion`, `contentHash`, `minAppVersion`, localização (`textKey`/arquivos de tradução), limites de tamanho e assinatura do pacote. Rejeite conteúdo desconhecido em vez de aceitar defaults silenciosos.

## 4. Motor e estado

`StoryEngine` mantém:

- `currentNodeId`: posição determinística;
- `choiceHistory`: snapshots imutáveis para desfazer/refazer;
- `visitedNodeIds`: telemetria e desbloqueios;
- `evidenceIds`: estado reativo do quadro;
- `keys`: recurso controlado pelo servidor;
- `endingId`: final calculado após validar requisitos.

`StorySessionController` expõe o estado por `ChangeNotifier`. Na UI, use `AnimatedBuilder`, Provider ou Riverpod sem alterar o domínio. A operação de desfazer consome uma chave e nunca aceita um índice enviado pela UI.

## 5. Segurança e threat model

### Armazenamento local

`SecureProgressStore` usa `flutter_secure_storage`, que delega ao Keystore no Android, e adiciona HMAC para detectar corrupção/adulteração. Isso protege confidencialidade e integridade contra inspeção casual, mas **não é uma barreira contra dispositivo rooteado, debugger ou APK modificado**. Portanto:

- o progresso local é cache, não autoridade;
- chaves, moedas, compras e recompensas são reconciliadas com o servidor;
- endpoints recalculam saldo e aceitam apenas comandos idempotentes;
- não armazene tokens em SharedPreferences, logs ou analytics;
- use backup rules para não exportar segredos do Keystore;
- limpe sessão e dados sensíveis no logout;
- não permita que o cliente escolha `userId`, preço ou valor de recompensa.

O código usa `Random.secure()` para gerar a chave uma única vez no Keystore; a produção deve incluir rotação/versionamento e migração de envelopes.

### Auth e backend

- Firebase Auth com email/OIDC, refresh token gerenciado pelo SDK e MFA quando aplicável.
- Firebase App Check (Play Integrity no Android) para reduzir abuso automatizado.
- Firestore Security Rules: usuário só acessa documentos cujo ID é `request.auth.uid`; escrita de saldo somente por Cloud Functions/Admin SDK.
- TLS padrão do SDK; não desabilite verificação de certificado.
- Remote Config/flags não são controles de segurança.
- Rate limit, auditoria, idempotency key e validação de schema no backend.
- Separe projetos Firebase `dev`, `staging` e `prod`; não comite `google-services.json` de produção.

## 6. JSON Schema mínimo recomendado

Em produção, valide no CI e no servidor. O shape equivalente ao exemplo é:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["id", "version", "title", "synopsis", "cover", "category", "startNodeId", "nodes", "endings"],
  "properties": {
    "id": {"type": "string", "pattern": "^[a-z0-9-]+$"},
    "version": {"type": "integer", "minimum": 1},
    "title": {"type": "string", "minLength": 1, "maxLength": 120},
    "synopsis": {"type": "string", "maxLength": 1000},
    "cover": {"type": "string"},
    "category": {"enum": ["suspense", "drama", "murder"]},
    "startNodeId": {"type": "string"},
    "nodes": {
      "type": "object",
      "additionalProperties": {"$ref": "#/$defs/node"}
    },
    "endings": {
      "type": "object",
      "additionalProperties": {"$ref": "#/$defs/ending"}
    }
  },
  "$defs": {
    "choice": {
      "type": "object",
      "required": ["id", "label", "requires", "addEvidence", "removeEvidence", "keyCost"],
      "properties": {
        "id": {"type": "string"},
        "label": {"type": "string", "maxLength": 240},
        "nextNodeId": {"type": ["string", "null"]},
        "endingId": {"type": ["string", "null"]},
        "requires": {"type": "array", "items": {"type": "string"}, "uniqueItems": true},
        "addEvidence": {"type": "array", "items": {"type": "string"}, "uniqueItems": true},
        "removeEvidence": {"type": "array", "items": {"type": "string"}, "uniqueItems": true},
        "keyCost": {"type": "integer", "minimum": 0}
      },
      "additionalProperties": false
    },
    "node": {
      "type": "object",
      "required": ["id", "text", "choices"],
      "properties": {
        "id": {"type": "string"},
        "text": {"type": "string", "minLength": 1},
        "image": {"type": ["string", "null"]},
        "choices": {"type": "array", "items": {"$ref": "#/$defs/choice"}, "minItems": 1}
      },
      "additionalProperties": false
    },
    "ending": {
      "type": "object",
      "required": ["id", "title", "text", "requiredEvidence"],
      "properties": {
        "id": {"type": "string"},
        "title": {"type": "string"},
        "text": {"type": "string"},
        "requiredEvidence": {"type": "array", "items": {"type": "string"}, "uniqueItems": true}
      },
      "additionalProperties": false
    }
  },
  "additionalProperties": false
}
```

## 7. Qualidade e operação

- Testes unitários do parser, validação de requisitos, consumo de chaves e finais.
- Testes de propriedade para garantir que escolhas inválidas não mutam estado.
- Golden tests de layout para o Quadro de Investigação.
- Crash reporting sem texto de cenas, tokens ou PII.
- CI: `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, testes, validação de schema e scan de segredos.
- Conteúdo editorial passa por revisão, assinatura, rollout gradual e rollback por versão.
