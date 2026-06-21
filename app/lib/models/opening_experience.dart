class OpeningCardData {
  final String id;
  final String title;
  final String body;
  final String ctaLabel;
  final String actionRoute;
  final Map<String, dynamic>? actionExtra;
  final String tone;

  const OpeningCardData({
    required this.id,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.actionRoute,
    this.actionExtra,
    this.tone = 'default',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'ctaLabel': ctaLabel,
        'actionRoute': actionRoute,
        'actionExtra': actionExtra,
        'tone': tone,
      };

  factory OpeningCardData.fromJson(Map<String, dynamic> json) {
    return OpeningCardData(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      ctaLabel: json['ctaLabel'] as String,
      actionRoute: json['actionRoute'] as String,
      actionExtra: json['actionExtra'] == null
          ? null
          : Map<String, dynamic>.from(
              json['actionExtra'] as Map,
            ),
      tone: (json['tone'] as String?) ?? 'default',
    );
  }
}
