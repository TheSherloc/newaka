class Subscription {
  const Subscription({required this.url, this.lastFetched, this.lastError});

  final String url;
  final DateTime? lastFetched;
  final String? lastError;

  Subscription copyWith({
    String? url,
    DateTime? lastFetched,
    String? lastError,
    bool clearError = false,
  }) =>
      Subscription(
        url: url ?? this.url,
        lastFetched: lastFetched ?? this.lastFetched,
        lastError: clearError ? null : (lastError ?? this.lastError),
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'lastFetched': lastFetched?.toIso8601String(),
        'lastError': lastError,
      };

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        url: json['url'] as String,
        lastFetched: json['lastFetched'] == null
            ? null
            : DateTime.parse(json['lastFetched'] as String),
        lastError: json['lastError'] as String?,
      );
}
