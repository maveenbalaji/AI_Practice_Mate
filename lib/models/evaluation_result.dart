class EvaluationResult {
  final String status; // PASS, FAIL, ERROR
  final String feedback;
  final String? nextAction; // NEXT_CHALLENGE, TRY_AGAIN, HINT
  final bool canProgress;
  final int? xpEarned;

  EvaluationResult({
    required this.status,
    required this.feedback,
    this.nextAction,
    required this.canProgress,
    this.xpEarned,
  });

  factory EvaluationResult.fromJson(Map<String, dynamic> json) {
    return EvaluationResult(
      status: json['status'] as String,
      feedback: json['feedback'] as String,
      nextAction: json['next_action'] as String?,
      canProgress: json['can_progress'] as bool,
      xpEarned: json['xp_earned'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['feedback'] = feedback;
    if (nextAction != null) data['next_action'] = nextAction;
    data['can_progress'] = canProgress;
    if (xpEarned != null) data['xp_earned'] = xpEarned;
    return data;
  }
}
