import '../api/models.dart';

/// WP-D: the media library and the team.
///
/// Counts arrive as the number and its digits already formatted for the
/// page (`context.adminFormats.integer`), so each language picks its own
/// plural and the digits match the rest of the page. Names arrive isolated
/// (`bidiIsolate`), so an Arabic name keeps its order in a Latin sentence.
abstract class MediaTeamStrings {
  const MediaTeamStrings();

  // media
  String get mediaTitle;
  String mediaSubtitle(int count, String countText);
  String get usage;
  String get usageAll;
  String get usageInUse;
  String get usageUnused;
  String usedIn(int count, String countText);
  String get crop;
  String cropApplied(String name);
  String altSaved(String name);

  // team
  String get teamTitle;
  String teamSubtitle(int invited, String activeText, String invitedText);
  String get inviteTeammate;
  String get inviteDescription;
  String get columnMember;
  String get columnRole;
  String get columnStatus;
  String get columnLastActive;
  String get notYet;
  String get you;
  String get email;
  String get role;
  String roleDescription(Role role);
  String get sendInvitation;
  String get alreadyOnTeam;
  String invitationSent(String email);
  String memberActions(String name);
  String get changeRole;
  String get deactivate;
  String deactivateTitle(String name);
  String deactivateMessage(String name);
  String deactivated(String name);
  String roleChanged(String name, String role);
  String get noTeamTitle;
  String get noTeamMessage;
}

class MediaTeamStringsEn extends MediaTeamStrings {
  const MediaTeamStringsEn();

  @override
  String get mediaTitle => 'Media library';
  @override
  String mediaSubtitle(int count, String countText) => count == 1
      ? 'One picture for the catalogue'
      : '$countText pictures for the catalogue';
  @override
  String get usage => 'Usage';
  @override
  String get usageAll => 'All pictures';
  @override
  String get usageInUse => 'In use';
  @override
  String get usageUnused => 'Not used';
  @override
  String usedIn(int count, String countText) => switch (count) {
    0 => 'Not used by any product',
    1 => 'Used by one product',
    _ => 'Used by $countText products',
  };
  @override
  String get crop => 'Crop';
  @override
  String cropApplied(String name) => 'New crop for $name';
  @override
  String altSaved(String name) => 'Alt text saved for $name';

  @override
  String get teamTitle => 'Team';
  @override
  String teamSubtitle(int invited, String activeText, String invitedText) =>
      switch (invited) {
        0 => '$activeText active',
        1 => '$activeText active, one invitation pending',
        _ => '$activeText active, $invitedText invitations pending',
      };
  @override
  String get inviteTeammate => 'Invite teammate';
  @override
  String get inviteDescription =>
      'They get an email with a link to choose a password. The link lasts '
      'seven days.';
  @override
  String get columnMember => 'Member';
  @override
  String get columnRole => 'Role';
  @override
  String get columnStatus => 'Status';
  @override
  String get columnLastActive => 'Last active';
  @override
  String get notYet => 'Not yet';
  @override
  String get you => 'You';
  @override
  String get email => 'Email';
  @override
  String get role => 'Role';
  @override
  String roleDescription(Role role) => switch (role) {
    Role.owner => 'Everything, the team included',
    Role.manager => 'Everything but the team',
    Role.staff => 'Orders and the catalogue',
    Role.viewer => 'Can look, not change',
  };
  @override
  String get sendInvitation => 'Send invitation';
  @override
  String get alreadyOnTeam => 'Someone on the team already has this email';
  @override
  String invitationSent(String email) => 'Invitation sent to $email';
  @override
  String memberActions(String name) => 'Actions for $name';
  @override
  String get changeRole => 'Change role';
  @override
  String get deactivate => 'Deactivate';
  @override
  String deactivateTitle(String name) => 'Deactivate $name?';
  @override
  String deactivateMessage(String name) =>
      '$name is signed out and can no longer sign in. The orders and notes '
      'they worked on stay as they are.';
  @override
  String deactivated(String name) => '$name is deactivated';
  @override
  String roleChanged(String name, String role) => '$name is now $role';
  @override
  String get noTeamTitle => 'No one here yet';
  @override
  String get noTeamMessage => 'Invite a teammate to share the work.';
}

class MediaTeamStringsFr extends MediaTeamStrings {
  const MediaTeamStringsFr();

  @override
  String get mediaTitle => 'Médiathèque';
  @override
  String mediaSubtitle(int count, String countText) => count < 2
      ? '$countText image pour le catalogue'
      : '$countText images pour le catalogue';
  @override
  String get usage => 'Utilisation';
  @override
  String get usageAll => 'Toutes les images';
  @override
  String get usageInUse => 'Utilisées';
  @override
  String get usageUnused => 'Inutilisées';
  @override
  String usedIn(int count, String countText) => switch (count) {
    0 => 'Utilisée par aucun produit',
    1 => 'Utilisée par un produit',
    _ => 'Utilisée par $countText produits',
  };
  @override
  String get crop => 'Recadrer';
  @override
  String cropApplied(String name) => 'Nouveau recadrage pour $name';
  @override
  String altSaved(String name) => 'Texte alternatif enregistré pour $name';

  @override
  String get teamTitle => 'Équipe';
  @override
  String teamSubtitle(int invited, String activeText, String invitedText) =>
      switch (invited) {
        0 => '$activeText actifs',
        1 => '$activeText actifs, une invitation en attente',
        _ => '$activeText actifs, $invitedText invitations en attente',
      };
  @override
  String get inviteTeammate => 'Inviter un collègue';
  @override
  String get inviteDescription =>
      'Il ou elle reçoit un e-mail avec un lien pour choisir un mot de '
      'passe. Le lien est valable sept jours.';
  @override
  String get columnMember => 'Membre';
  @override
  String get columnRole => 'Rôle';
  @override
  String get columnStatus => 'Statut';
  @override
  String get columnLastActive => 'Dernière activité';
  @override
  String get notYet => 'Pas encore';
  @override
  String get you => 'Vous';
  @override
  String get email => 'E-mail';
  @override
  String get role => 'Rôle';
  @override
  String roleDescription(Role role) => switch (role) {
    Role.owner => 'Tout, l’équipe comprise',
    Role.manager => 'Tout sauf l’équipe',
    Role.staff => 'Les commandes et le catalogue',
    Role.viewer => 'Consulte sans modifier',
  };
  @override
  String get sendInvitation => 'Envoyer l’invitation';
  @override
  String get alreadyOnTeam => 'Un membre de l’équipe a déjà cet e-mail';
  @override
  String invitationSent(String email) => 'Invitation envoyée à $email';
  @override
  String memberActions(String name) => 'Actions pour $name';
  @override
  String get changeRole => 'Changer de rôle';
  @override
  String get deactivate => 'Désactiver';
  @override
  String deactivateTitle(String name) => 'Désactiver $name ?';
  @override
  String deactivateMessage(String name) =>
      '$name est déconnecté et ne peut plus se connecter. Les commandes et '
      'les notes restent telles quelles.';
  @override
  String deactivated(String name) => '$name est désactivé';
  @override
  String roleChanged(String name, String role) =>
      'Nouveau rôle pour $name : $role';
  @override
  String get noTeamTitle => 'Personne pour l’instant';
  @override
  String get noTeamMessage => 'Invitez un collègue pour partager le travail.';
}

class MediaTeamStringsAr extends MediaTeamStrings {
  const MediaTeamStringsAr();

  @override
  String get mediaTitle => 'مكتبة الوسائط';
  @override
  String mediaSubtitle(int count, String countText) =>
      'صور الكتالوج: $countText';
  @override
  String get usage => 'الاستخدام';
  @override
  String get usageAll => 'كل الصور';
  @override
  String get usageInUse => 'مستخدمة';
  @override
  String get usageUnused => 'غير مستخدمة';
  @override
  String usedIn(int count, String countText) => switch (count) {
    0 => 'لا يستخدمها أي منتج',
    1 => 'يستخدمها منتج واحد',
    _ => 'عدد المنتجات التي تستخدمها: $countText',
  };
  @override
  String get crop => 'قص';
  @override
  String cropApplied(String name) => 'قص جديد للصورة $name';
  @override
  String altSaved(String name) => 'تم حفظ النص البديل للصورة $name';

  @override
  String get teamTitle => 'الفريق';
  @override
  String teamSubtitle(int invited, String activeText, String invitedText) =>
      switch (invited) {
        0 => 'الأعضاء النشطون: $activeText',
        1 => 'الأعضاء النشطون: $activeText، ودعوة واحدة معلّقة',
        _ => 'الأعضاء النشطون: $activeText، والدعوات المعلّقة: $invitedText',
      };
  @override
  String get inviteTeammate => 'دعوة زميل';
  @override
  String get inviteDescription =>
      'يصله بريد إلكتروني فيه رابط لاختيار كلمة مرور. الرابط صالح سبعة أيام.';
  @override
  String get columnMember => 'العضو';
  @override
  String get columnRole => 'الدور';
  @override
  String get columnStatus => 'الحالة';
  @override
  String get columnLastActive => 'آخر نشاط';
  @override
  String get notYet => 'ليس بعد';
  @override
  String get you => 'أنت';
  @override
  String get email => 'البريد الإلكتروني';
  @override
  String get role => 'الدور';
  @override
  String roleDescription(Role role) => switch (role) {
    Role.owner => 'كل شيء، بما في ذلك الفريق',
    Role.manager => 'كل شيء ما عدا الفريق',
    Role.staff => 'الطلبات والكتالوج',
    Role.viewer => 'يطّلع دون أن يعدّل',
  };
  @override
  String get sendInvitation => 'إرسال الدعوة';
  @override
  String get alreadyOnTeam => 'هذا البريد الإلكتروني لعضو في الفريق بالفعل';
  @override
  String invitationSent(String email) => 'أُرسلت الدعوة إلى $email';
  @override
  String memberActions(String name) => 'إجراءات $name';
  @override
  String get changeRole => 'تغيير الدور';
  @override
  String get deactivate => 'تعطيل';
  @override
  String deactivateTitle(String name) => 'تعطيل حساب $name؟';
  @override
  String deactivateMessage(String name) =>
      'يُسجَّل خروج $name ولا يعود بإمكانه تسجيل الدخول. تبقى الطلبات '
      'والملاحظات كما هي.';
  @override
  String deactivated(String name) => 'تم تعطيل حساب $name';
  @override
  String roleChanged(String name, String role) =>
      'الدور الجديد لـ $name: $role';
  @override
  String get noTeamTitle => 'لا أحد هنا بعد';
  @override
  String get noTeamMessage => 'ادعُ زميلًا لمشاركة العمل.';
}
