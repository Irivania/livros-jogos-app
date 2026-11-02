# Livros-Jogos

Base técnica de um aplicativo Flutter multiplataforma para histórias interativas de suspense, drama e investigação.

## Princípios

- **Feature-first + Clean Architecture:** domínio não conhece Flutter, Firebase ou armazenamento.
- **Conteúdo orientado a dados:** novas histórias são pacotes JSON versionados; o motor não contém regras específicas de uma história.
- **Security-first:** progresso local é tratado como cache protegido, nunca como fonte de verdade para moedas, compras ou recompensas.
- **Offline-first controlado:** o usuário pode continuar uma sessão já baixada; sincronização e concessão de recursos sensíveis são validadas pelo backend.

## Estrutura

```text
assets/stories/                 Conteúdo empacotado para desenvolvimento/offline
docs/ARCHITECTURE.md            Decisões, threat model e fluxo de publicação
lib/core/                       Falhas, segurança e contratos compartilhados
lib/features/story_engine/      Entidades, parser, motor e estado reativo
lib/features/auth/              Contrato de autenticação
```

## Próximos passos

1. Criar o projeto Flutter (`flutter create .`) ou mover este código para um projeto já criado.
2. Executar `flutter pub get`.
3. Configurar Firebase por ambiente (`flutterfire configure`) e regras do backend.
4. Publicar os pacotes de histórias em um CDN assinado, após validação de schema e assinatura.

Detalhes de implementação, segurança e o contrato JSON estão em [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
