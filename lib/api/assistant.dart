import 'graphql_client.dart';

/// A listing the assistant cited in its answer.
class AiSource {
  AiSource({
    required this.type,
    required this.id,
    required this.title,
    this.subtitle,
    this.price,
    this.currency,
    this.image,
  });

  /// PROPERTY | PART | ARTICLE
  final String type;
  final String id;
  final String title;
  final String? subtitle;
  final num? price;
  final String? currency;
  final String? image;

  factory AiSource.fromJson(Map<String, dynamic> j) => AiSource(
        type: '${j['sourceType']}',
        id: '${j['sourceId']}',
        title: '${j['title'] ?? ''}',
        subtitle: j['subtitle'] as String?,
        price: j['price'] as num?,
        currency: j['currency'] as String?,
        image: j['image'] as String?,
      );
}

class ChatTurn {
  ChatTurn.user(this.text)
      : isUser = true,
        sources = const [],
        isError = false;
  ChatTurn.assistant(this.text, this.sources)
      : isUser = false,
        isError = false;
  ChatTurn.error(this.text)
      : isUser = false,
        sources = const [],
        isError = true;

  final bool isUser;
  final String text;
  final List<AiSource> sources;
  final bool isError;
}

/// RAG assistant on the backend (askAssistant): answers from MotoHub listings.
/// The server keeps no chat state, so earlier turns are sent along each time.
class AssistantApi {
  AssistantApi._();
  static final AssistantApi instance = AssistantApi._();

  Future<ChatTurn> ask(String message, List<ChatTurn> history) async {
    final data = await GraphQLClient.instance.query(r'''
      mutation ($input: AiChatInput!) {
        askAssistant(input: $input) {
          answer
          sources { sourceType sourceId title subtitle price currency image }
        }
      }
    ''', variables: {
      'input': {
        'message': message,
        'history': [
          for (final t in history.where((t) => !t.isError))
            {'role': t.isUser ? 'user' : 'assistant', 'content': t.text},
        ],
      },
    });
    final result = data['askAssistant'] as Map<String, dynamic>;
    return ChatTurn.assistant(
      '${result['answer'] ?? ''}',
      ((result['sources'] as List?) ?? const []).map((e) => AiSource.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
