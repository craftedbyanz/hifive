import '../../domain/repositories/repositories.dart';
import '../../l10n/l10n.dart';

/// What to tell the learner when sharing fails.
String shareErrorText(AppLocalizations t, Object error) =>
    switch (error is ShareException ? error.error : ShareError.unavailable) {
      ShareError.notFound => t.shareErrorNotFound,
      ShareError.unavailable => t.shareErrorOffline,
      ShareError.unauthorized => t.shareErrorSignIn,
      ShareError.tooMany => t.shareErrorTooMany,
      ShareError.rejected => t.shareErrorRejected,
    };
