import '../api/shop_api.dart';

/// WP-B: orders, the board, order detail and customers.
abstract class OrdersStrings {
  const OrdersStrings();

  // the queue
  String get orderBoardTitle;
  String get viewList;
  String get viewBoard;
  String get viewSwitchLabel;
  String get searchOrders;
  String get exportCsv;
  String get moreActions;
  String get filters;

  /// The phone's Filters button with [count] filters on, [formatted] in the
  /// page's digits.
  String filtersCount(int count, String formatted);
  String get showResults;
  String get noOrdersTitle;
  String get noOrdersMessage;

  // the seeded shared views, which the shop names in English
  String get viewAll;
  String get viewToShip;
  String get viewRefundRequests;

  // columns and filters
  String get columnOrder;
  String get columnCustomer;
  String get columnPlaced;
  String get columnStatus;
  String get columnPayment;
  String get columnItems;
  String get columnTotal;
  String get refundRequested;

  // selection and bulk actions
  String get markShipped;

  /// The order page's own action: one order, where [markShipped] is the
  /// selection's.
  String get markOrderShipped;
  String get markPacked;
  String ordersSelected(int count);
  String allOrdersSelected(int count);
  String markedShipped(int count);
  String markedPacked(int count);

  /// After Undo: the orders are back as they were, and picked again.
  String undoneBulk(int count);
  String get bulkFailed;
  String get bulkFailedTitle;

  // export
  String exportTitle(int count);
  String get exportDescription;
  String get exportFileName;
  String get copyCsv;
  String get done;

  // the row menu and the customer card
  String get openOrder;
  String get changeStatus;
  String get viewCustomer;
  String get copyNumber;
  String customerSince(String date);
  String get vip;
  String get wholesale;
  String countryName(String code);

  /// A city and its country on one line.
  String place(String city, String country);
  String statusChanged(String label, String status);
  String statusFailed(String label);

  // the board
  String boardColumnSubtitle(OrderStatus status);
  String get emptyColumn;
  String moveFailed(String label);

  // order detail
  String get breadcrumbOrders;
  String placedOn(String date);
  String get shipAndEmail;
  String get shipAndEmailHint;
  String get more;
  String get refund;
  String get cancelOrder;
  String get items;
  String get summary;
  String get subtotal;
  String get shipping;
  String get free;
  String taxIncluded(String rate);
  String get total;
  String get refunded;
  String get customer;
  String get shipTo;
  String get payment;
  String get channel;
  String get activity;
  String get notes;
  String quantity(int qty);
  String get eachPrice;
  String event(OrderEventKind kind);
  String byWhom(String name);
  String get byCustomer;
  String refundDetail(String amount, String reason);
  String updating(String label);
  String get orderNotFoundTitle;
  String orderNotFoundMessage(String label);
  String get backToOrders;

  // refund
  String refundTitle(String label);
  String get refundAction;
  String get awaitingPayment;

  /// The payment card's pill once the money is in: not the order status's
  /// word, which the header's pill already says in another tone.
  String get paymentReceived;
  String get fullyRefunded;
  String get refundDescription;
  String get amount;
  String refundableHint(String amount);
  String get reason;
  String get reasonHint;
  String get refundTooHigh;
  String get refundChanged;
  String get refundInvalid;
  String refundDone(String amount, String label);
  String get nothingToRefund;

  // cancel
  String cancelTitle(String label);
  String get cancelMessage;
  String get keepOrder;
  String cancelled(String label);

  // notes and mentions
  String get noteLabel;
  String get noteHint;
  String get addNote;
  String get noteAdded;
  String get noNotes;

  // customers
  String get searchCustomers;
  String get columnEmail;
  String get columnCity;
  String get columnTags;
  String get columnSince;
  String get noCustomersTitle;
  String get noCustomersMessage;
  String get customerDetails;
  String get customerOrders;
  String get email;
  String get city;
  String get country;
  String get tags;
  String get noTags;
  String customerSummary(String name, int orders);

  /// A link to a customer's newest order, [label] its number.
  String latestOrder(String label);
  String get emailCustomer;
  String get noCustomerOrders;

  // deleting a view
  String deleteViewTitle(String name);
  String get deleteViewMessage;
  String get deleteView;
}

class OrdersStringsEn extends OrdersStrings {
  const OrdersStringsEn();

  @override
  String get orderBoardTitle => 'Order board';
  @override
  String get viewList => 'List';
  @override
  String get viewBoard => 'Board';
  @override
  String get viewSwitchLabel => 'Show orders as';
  @override
  String get searchOrders => 'Number, customer, email…';
  @override
  String get exportCsv => 'Export CSV';
  @override
  String get moreActions => 'More actions';
  @override
  String get filters => 'Filters';
  @override
  String filtersCount(int count, String formatted) => 'Filters ($formatted)';
  @override
  String get showResults => 'Show results';
  @override
  String get noOrdersTitle => 'No orders yet';
  @override
  String get noOrdersMessage =>
      'Orders placed on the shop and at the market stall land here.';
  @override
  String get viewAll => 'All';
  @override
  String get viewToShip => 'To ship';
  @override
  String get viewRefundRequests => 'Refund requests';
  @override
  String get columnOrder => 'Order';
  @override
  String get columnCustomer => 'Customer';
  @override
  String get columnPlaced => 'Placed';
  @override
  String get columnStatus => 'Status';
  @override
  String get columnPayment => 'Payment';
  @override
  String get columnItems => 'Items';
  @override
  String get columnTotal => 'Total';
  @override
  String get refundRequested => 'Refund requested';
  @override
  String get markShipped => 'Mark shipped';
  @override
  String get markOrderShipped => 'Mark shipped';
  @override
  String get markPacked => 'Mark packed';
  @override
  String ordersSelected(int count) =>
      count == 1 ? '1 order selected' : '$count orders selected';
  @override
  String allOrdersSelected(int count) => 'All $count orders selected';
  @override
  String markedShipped(int count) =>
      count == 1 ? '1 order marked shipped' : '$count orders marked shipped';
  @override
  String markedPacked(int count) =>
      count == 1 ? '1 order marked packed' : '$count orders marked packed';
  @override
  String undoneBulk(int count) => count == 1
      ? 'Undone: the order is as it was'
      : 'Undone: $count orders are as they were';
  @override
  String get bulkFailedTitle => 'Nothing was changed';
  @override
  String get bulkFailed =>
      'The shop refused the change, so the orders are back as they were.';
  @override
  String exportTitle(int count) =>
      count == 1 ? '1 order exported' : '$count orders exported';
  @override
  String get exportDescription =>
      'The orders the current filters match, every page, in UTF-8.';
  @override
  String get exportFileName => 'orders.csv';
  @override
  String get copyCsv => 'Copy CSV';
  @override
  String get done => 'Done';
  @override
  String get openOrder => 'Open order';
  @override
  String get changeStatus => 'Change status';
  @override
  String get viewCustomer => 'View customer';
  @override
  String get copyNumber => 'Copy order number';
  @override
  String customerSince(String date) => 'Customer since $date';
  @override
  String get vip => 'VIP';
  @override
  String get wholesale => 'Wholesale';
  @override
  String countryName(String code) => switch (code) {
    'FR' => 'France',
    'BE' => 'Belgium',
    'NL' => 'Netherlands',
    'PT' => 'Portugal',
    'CH' => 'Switzerland',
    'AT' => 'Austria',
    'DE' => 'Germany',
    'LU' => 'Luxembourg',
    _ => code,
  };
  @override
  String statusChanged(String label, String status) => '$label is now $status';
  @override
  String statusFailed(String label) => '$label wasn’t updated';
  @override
  String boardColumnSubtitle(OrderStatus status) => switch (status) {
    OrderStatus.paid => 'Ready to pick',
    OrderStatus.picking => 'On the bench',
    OrderStatus.packed => 'Waiting for the carrier',
    OrderStatus.shipped => 'With the carrier',
    _ => '',
  };
  @override
  String get emptyColumn => 'Nothing here';
  @override
  String moveFailed(String label) =>
      'Couldn’t move $label, so it’s back where it was.';
  @override
  String get breadcrumbOrders => 'Orders';
  @override
  String placedOn(String date) => 'Placed $date';
  @override
  String get shipAndEmail => 'Ship and email the customer';
  @override
  String get shipAndEmailHint => 'Sends the tracking link';
  @override
  String get more => 'More';
  @override
  String get refund => 'Refund…';
  @override
  String get cancelOrder => 'Cancel order';
  @override
  String get items => 'Items';
  @override
  String get summary => 'Summary';
  @override
  String get subtotal => 'Subtotal';
  @override
  String get shipping => 'Shipping';
  @override
  String get free => 'Free';
  @override
  String taxIncluded(String rate) => 'VAT included ($rate)';
  @override
  String get total => 'Total';
  @override
  String get refunded => 'Refunded';
  @override
  String get customer => 'Customer';
  @override
  String get shipTo => 'Ship to';
  @override
  String get payment => 'Payment';
  @override
  String get channel => 'Channel';
  @override
  String get activity => 'Activity';
  @override
  String get notes => 'Notes';
  @override
  String quantity(int qty) => '× $qty';
  @override
  String get eachPrice => 'each';
  @override
  String event(OrderEventKind kind) => switch (kind) {
    OrderEventKind.placed => 'Order placed',
    OrderEventKind.paid => 'Payment received',
    OrderEventKind.picking => 'Picking started',
    OrderEventKind.packed => 'Packed',
    OrderEventKind.shipped => 'Handed to the carrier',
    OrderEventKind.delivered => 'Delivered',
    OrderEventKind.cancelled => 'Cancelled',
    OrderEventKind.refunded => 'Refund issued',
    OrderEventKind.note => 'Note',
    OrderEventKind.emailed => 'Customer emailed',
  };
  @override
  String byWhom(String name) => 'by $name';
  @override
  String get byCustomer => 'by the customer';
  @override
  String refundDetail(String amount, String reason) =>
      reason.isEmpty ? amount : '$amount · $reason';
  @override
  String updating(String label) => 'Updating $label…';
  @override
  String get orderNotFoundTitle => 'Order not found';
  @override
  String orderNotFoundMessage(String label) =>
      'There’s no order $label. It may have been typed wrong.';
  @override
  String get backToOrders => 'Back to orders';
  @override
  String refundTitle(String label) => 'Refund $label';
  @override
  String get refundDescription =>
      'The money goes back the way the customer paid.';
  @override
  String get amount => 'Amount';
  @override
  String refundableHint(String amount) => 'Up to $amount can be refunded.';
  @override
  String get reason => 'Reason';
  @override
  String get reasonHint => 'Arrived damaged';
  @override
  String get refundTooHigh => 'That’s more than is left to refund.';
  @override
  String get refundChanged =>
      'Someone refunded part of this order meanwhile. Check the amount and try again.';
  @override
  String get refundInvalid => 'Enter an amount above zero.';
  @override
  String refundDone(String amount, String label) =>
      '$amount refunded on $label';
  @override
  String get nothingToRefund => 'Nothing left to refund';
  @override
  String cancelTitle(String label) => 'Cancel $label?';
  @override
  String get cancelMessage =>
      'The customer is told, and the order leaves the queue. This can’t be '
      'undone.';
  @override
  String get keepOrder => 'Keep order';
  @override
  String cancelled(String label) => '$label cancelled';
  @override
  String get noteLabel => 'Add a note';
  @override
  String get noteHint => 'Only the team sees notes. Type @ to mention someone.';
  @override
  String get addNote => 'Add note';
  @override
  String get noteAdded => 'Note added';
  @override
  String get noNotes => 'No notes yet.';
  @override
  String get searchCustomers => 'Search name, email, city…';
  @override
  String get columnEmail => 'Email';
  @override
  String get columnCity => 'City';
  @override
  String get columnTags => 'Tags';
  @override
  String get columnSince => 'Customer since';
  @override
  String get noCustomersTitle => 'No customers yet';
  @override
  String get noCustomersMessage =>
      'Everyone who orders from the shop shows up here.';
  @override
  String get customerDetails => 'Details';
  @override
  String get customerOrders => 'Orders';
  @override
  String get email => 'Email';
  @override
  String get city => 'City';
  @override
  String get country => 'Country';
  @override
  String get tags => 'Tags';
  @override
  String get noTags => 'None';
  @override
  String customerSummary(String name, int orders) => switch (orders) {
    0 => '$name hasn’t ordered yet.',
    1 => '$name has placed 1 order.',
    _ => '$name has placed $orders orders.',
  };
  @override
  String latestOrder(String label) => 'Latest order: $label';
  @override
  String get emailCustomer => 'Write an email';
  @override
  String get noCustomerOrders => 'No orders yet.';
  @override
  String deleteViewTitle(String name) => 'Delete “$name”?';
  @override
  String get deleteViewMessage =>
      'Teammates who use this view lose it too. The orders stay as they are.';
  @override
  String get deleteView => 'Delete view';
  @override
  String get refundAction => 'Refund';
  @override
  String get awaitingPayment => 'Awaiting payment';
  @override
  String get paymentReceived => 'Received';
  @override
  String get fullyRefunded => 'Refunded';
  @override
  String place(String city, String country) => '$city, $country';
}

class OrdersStringsFr extends OrdersStrings {
  const OrdersStringsFr();

  @override
  String get orderBoardTitle => 'Tableau des commandes';
  @override
  String get viewList => 'Liste';
  @override
  String get viewBoard => 'Tableau';
  @override
  String get viewSwitchLabel => 'Afficher les commandes en';
  @override
  String get searchOrders => 'Numéro, client, e-mail…';
  @override
  String get exportCsv => 'Exporter en CSV';
  @override
  String get moreActions => 'Autres actions';
  @override
  String get filters => 'Filtres';
  @override
  String filtersCount(int count, String formatted) => 'Filtres ($formatted)';
  @override
  String get showResults => 'Voir les résultats';
  @override
  String get noOrdersTitle => 'Aucune commande pour l’instant';
  @override
  String get noOrdersMessage =>
      'Les commandes de la boutique et du marché arrivent ici.';
  @override
  String get viewAll => 'Toutes';
  @override
  String get viewToShip => 'À expédier';
  @override
  String get viewRefundRequests => 'Demandes de remboursement';
  @override
  String get columnOrder => 'N°';
  @override
  String get columnCustomer => 'Client';
  @override
  String get columnPlaced => 'Passée le';
  @override
  String get columnStatus => 'Statut';
  @override
  String get columnPayment => 'Paiement';
  @override
  String get columnItems => 'Qté';
  @override
  String get columnTotal => 'Total';
  @override
  String get refundRequested => 'Remboursement demandé';
  @override
  String get markShipped => 'Marquer expédiées';
  @override
  String get markOrderShipped => 'Marquer comme expédiée';
  @override
  String get markPacked => 'Marquer emballées';
  @override
  String ordersSelected(int count) =>
      count == 1 ? '1 commande sélectionnée' : '$count commandes sélectionnées';
  @override
  String allOrdersSelected(int count) =>
      'Les $count commandes sont sélectionnées';
  @override
  String markedShipped(int count) => count == 1
      ? '1 commande marquée expédiée'
      : '$count commandes marquées expédiées';
  @override
  String markedPacked(int count) => count == 1
      ? '1 commande marquée emballée'
      : '$count commandes marquées emballées';
  @override
  String undoneBulk(int count) => count == 1
      ? 'Annulé : la commande est revenue à son état'
      : 'Annulé : $count commandes sont revenues à leur état';
  @override
  String get bulkFailedTitle => 'Rien n’a été modifié';
  @override
  String get bulkFailed =>
      'La boutique a refusé la modification : les commandes sont revenues à '
      'leur état.';
  @override
  String exportTitle(int count) =>
      count == 1 ? '1 commande exportée' : '$count commandes exportées';
  @override
  String get exportDescription =>
      'Les commandes retenues par les filtres, toutes pages, en UTF-8.';
  @override
  String get exportFileName => 'orders.csv';
  @override
  String get copyCsv => 'Copier le CSV';
  @override
  String get done => 'Terminé';
  @override
  String get openOrder => 'Ouvrir la commande';
  @override
  String get changeStatus => 'Changer le statut';
  @override
  String get viewCustomer => 'Voir le client';
  @override
  String get copyNumber => 'Copier le numéro';
  @override
  String customerSince(String date) => 'Client depuis le $date';
  @override
  String get vip => 'VIP';
  @override
  String get wholesale => 'Revendeur';
  @override
  String countryName(String code) => switch (code) {
    'FR' => 'France',
    'BE' => 'Belgique',
    'NL' => 'Pays-Bas',
    'PT' => 'Portugal',
    'CH' => 'Suisse',
    'AT' => 'Autriche',
    'DE' => 'Allemagne',
    'LU' => 'Luxembourg',
    _ => code,
  };
  @override
  String statusChanged(String label, String status) =>
      '$label : $status désormais';
  @override
  String statusFailed(String label) => '$label n’a pas été modifiée';
  @override
  String boardColumnSubtitle(OrderStatus status) => switch (status) {
    OrderStatus.paid => 'Prêtes à préparer',
    OrderStatus.picking => 'Sur l’établi',
    OrderStatus.packed => 'En attente du transporteur',
    OrderStatus.shipped => 'Chez le transporteur',
    _ => '',
  };
  @override
  String get emptyColumn => 'Rien ici';
  @override
  String moveFailed(String label) =>
      'Impossible de déplacer $label : elle a repris sa place.';
  @override
  String get breadcrumbOrders => 'Commandes';
  @override
  String placedOn(String date) => 'Passée le $date';
  @override
  String get shipAndEmail => 'Expédier et prévenir le client';
  @override
  String get shipAndEmailHint => 'Envoie le lien de suivi';
  @override
  String get more => 'Plus';
  @override
  String get refund => 'Rembourser…';
  @override
  String get cancelOrder => 'Annuler la commande';
  @override
  String get items => 'Articles';
  @override
  String get summary => 'Récapitulatif';
  @override
  String get subtotal => 'Sous-total';
  @override
  String get shipping => 'Livraison';
  @override
  String get free => 'Offerte';
  @override
  String taxIncluded(String rate) => 'Dont TVA ($rate)';
  @override
  String get total => 'Total';
  @override
  String get refunded => 'Remboursé';
  @override
  String get customer => 'Client';
  @override
  String get shipTo => 'Livrer à';
  @override
  String get payment => 'Paiement';
  @override
  String get channel => 'Canal';
  @override
  String get activity => 'Historique';
  @override
  String get notes => 'Notes';
  @override
  String quantity(int qty) => '× $qty';
  @override
  String get eachPrice => 'l’unité';
  @override
  String event(OrderEventKind kind) => switch (kind) {
    OrderEventKind.placed => 'Commande passée',
    OrderEventKind.paid => 'Paiement reçu',
    OrderEventKind.picking => 'Préparation commencée',
    OrderEventKind.packed => 'Emballée',
    OrderEventKind.shipped => 'Remise au transporteur',
    OrderEventKind.delivered => 'Livrée',
    OrderEventKind.cancelled => 'Annulée',
    OrderEventKind.refunded => 'Remboursement effectué',
    OrderEventKind.note => 'Note',
    OrderEventKind.emailed => 'Client prévenu par e-mail',
  };
  @override
  String byWhom(String name) => 'par $name';
  @override
  String get byCustomer => 'par le client';
  @override
  String refundDetail(String amount, String reason) =>
      reason.isEmpty ? amount : '$amount · $reason';
  @override
  String updating(String label) => 'Mise à jour de $label…';
  @override
  String get orderNotFoundTitle => 'Commande introuvable';
  @override
  String orderNotFoundMessage(String label) =>
      'Aucune commande $label. Le numéro est peut-être mal saisi.';
  @override
  String get backToOrders => 'Retour aux commandes';
  @override
  String refundTitle(String label) => 'Rembourser $label';
  @override
  String get refundDescription =>
      'L’argent repart par le moyen de paiement du client.';
  @override
  String get amount => 'Montant';
  @override
  String refundableHint(String amount) =>
      'Jusqu’à $amount peuvent être remboursés.';
  @override
  String get reason => 'Motif';
  @override
  String get reasonHint => 'Arrivée abîmée';
  @override
  String get refundTooHigh => 'C’est plus que ce qui reste à rembourser.';
  @override
  String get refundChanged =>
      'Quelqu’un a remboursé une partie de cette commande entre-temps. Vérifiez le montant et réessayez.';
  @override
  String get refundInvalid => 'Saisissez un montant supérieur à zéro.';
  @override
  String refundDone(String amount, String label) =>
      '$amount remboursés sur $label';
  @override
  String get nothingToRefund => 'Plus rien à rembourser';
  @override
  String cancelTitle(String label) => 'Annuler $label ?';
  @override
  String get cancelMessage =>
      'Le client est prévenu et la commande quitte la file. C’est '
      'définitif.';
  @override
  String get keepOrder => 'Garder la commande';
  @override
  String cancelled(String label) => '$label annulée';
  @override
  String get noteLabel => 'Ajouter une note';
  @override
  String get noteHint =>
      'Seule l’équipe voit les notes. Tapez @ pour mentionner quelqu’un.';
  @override
  String get addNote => 'Ajouter la note';
  @override
  String get noteAdded => 'Note ajoutée';
  @override
  String get noNotes => 'Aucune note pour l’instant.';
  @override
  String get searchCustomers => 'Nom, e-mail, ville…';
  @override
  String get columnEmail => 'E-mail';
  @override
  String get columnCity => 'Ville';
  @override
  String get columnTags => 'Étiquettes';
  @override
  String get columnSince => 'Client depuis';
  @override
  String get noCustomersTitle => 'Aucun client pour l’instant';
  @override
  String get noCustomersMessage =>
      'Toute personne qui commande à la boutique apparaît ici.';
  @override
  String get customerDetails => 'Détails';
  @override
  String get customerOrders => 'Commandes';
  @override
  String get email => 'E-mail';
  @override
  String get city => 'Ville';
  @override
  String get country => 'Pays';
  @override
  String get tags => 'Étiquettes';
  @override
  String get noTags => 'Aucune';
  @override
  String customerSummary(String name, int orders) => switch (orders) {
    0 => '$name n’a encore rien commandé.',
    1 => '$name a passé 1 commande.',
    _ => '$name a passé $orders commandes.',
  };
  @override
  String latestOrder(String label) => 'Dernière commande : $label';
  @override
  String get emailCustomer => 'Écrire un e-mail';
  @override
  String get noCustomerOrders => 'Aucune commande pour l’instant.';
  @override
  String deleteViewTitle(String name) => 'Supprimer « $name » ?';
  @override
  String get deleteViewMessage =>
      'L’équipe la perd aussi si elle l’utilisait. Les commandes ne changent pas.';
  @override
  String get deleteView => 'Supprimer la vue';
  @override
  String get refundAction => 'Rembourser';
  @override
  String get awaitingPayment => 'En attente de paiement';
  @override
  String get paymentReceived => 'Encaissé';
  @override
  String get fullyRefunded => 'Remboursée';
  @override
  String place(String city, String country) => '$city, $country';
}

class OrdersStringsAr extends OrdersStrings {
  const OrdersStringsAr();

  @override
  String get orderBoardTitle => 'لوحة الطلبات';
  @override
  String get viewList => 'قائمة';
  @override
  String get viewBoard => 'لوحة';
  @override
  String get viewSwitchLabel => 'عرض الطلبات على شكل';
  @override
  String get searchOrders => 'الرقم أو العميل أو البريد…';
  @override
  String get exportCsv => 'تصدير CSV';
  @override
  String get moreActions => 'إجراءات أخرى';
  @override
  String get filters => 'عوامل التصفية';
  @override
  String filtersCount(int count, String formatted) =>
      'عوامل التصفية ($formatted)';
  @override
  String get showResults => 'عرض النتائج';
  @override
  String get noOrdersTitle => 'لا توجد طلبات بعد';
  @override
  String get noOrdersMessage => 'تصل هنا طلبات المتجر وطلبات كشك السوق.';
  @override
  String get viewAll => 'الكل';
  @override
  String get viewToShip => 'للشحن';
  @override
  String get viewRefundRequests => 'طلبات الاسترداد';
  @override
  String get columnOrder => 'الطلب';
  @override
  String get columnCustomer => 'العميل';
  @override
  String get columnPlaced => 'تاريخ الطلب';
  @override
  String get columnStatus => 'الحالة';
  @override
  String get columnPayment => 'الدفع';
  @override
  String get columnItems => 'القطع';
  @override
  String get columnTotal => 'الإجمالي';
  @override
  String get refundRequested => 'طُلب استرداد';
  @override
  String get markShipped => 'وضع علامة شُحن';
  @override
  String get markOrderShipped => 'وضع علامة شُحن';
  @override
  String get markPacked => 'وضع علامة غُلّف';
  @override
  String ordersSelected(int count) => switch (count) {
    1 => 'تم تحديد طلب واحد',
    2 => 'تم تحديد طلبين',
    <= 10 => 'تم تحديد $count طلبات',
    _ => 'تم تحديد $count طلبًا',
  };
  @override
  String allOrdersSelected(int count) => 'تم تحديد كل الطلبات ($count)';
  @override
  String markedShipped(int count) => switch (count) {
    1 => 'وُضعت علامة شُحن على طلب واحد',
    2 => 'وُضعت علامة شُحن على طلبين',
    <= 10 => 'وُضعت علامة شُحن على $count طلبات',
    _ => 'وُضعت علامة شُحن على $count طلبًا',
  };
  @override
  String markedPacked(int count) => switch (count) {
    1 => 'وُضعت علامة غُلّف على طلب واحد',
    2 => 'وُضعت علامة غُلّف على طلبين',
    <= 10 => 'وُضعت علامة غُلّف على $count طلبات',
    _ => 'وُضعت علامة غُلّف على $count طلبًا',
  };
  @override
  String undoneBulk(int count) => switch (count) {
    1 => 'تم التراجع: عاد الطلب كما كان',
    2 => 'تم التراجع: عاد الطلبان كما كانا',
    <= 10 => 'تم التراجع: عادت $count طلبات كما كانت',
    _ => 'تم التراجع: عاد $count طلبًا كما كان',
  };
  @override
  String get bulkFailedTitle => 'لم يتغيّر شيء';
  @override
  String get bulkFailed => 'رفض المتجر التغيير، فعادت الطلبات كما كانت.';
  @override
  String exportTitle(int count) => switch (count) {
    1 => 'تم تصدير طلب واحد',
    2 => 'تم تصدير طلبين',
    <= 10 => 'تم تصدير $count طلبات',
    _ => 'تم تصدير $count طلبًا',
  };
  @override
  String get exportDescription =>
      'الطلبات المطابقة لعوامل التصفية الحالية، من كل الصفحات، بترميز UTF-8.';
  @override
  String get exportFileName => 'orders.csv';
  @override
  String get copyCsv => 'نسخ CSV';
  @override
  String get done => 'تم';
  @override
  String get openOrder => 'فتح الطلب';
  @override
  String get changeStatus => 'تغيير الحالة';
  @override
  String get viewCustomer => 'عرض العميل';
  @override
  String get copyNumber => 'نسخ رقم الطلب';
  @override
  String customerSince(String date) => 'عميل منذ $date';
  @override
  String get vip => 'مميّز';
  @override
  String get wholesale => 'تاجر جملة';
  @override
  String countryName(String code) => switch (code) {
    'FR' => 'فرنسا',
    'BE' => 'بلجيكا',
    'NL' => 'هولندا',
    'PT' => 'البرتغال',
    'CH' => 'سويسرا',
    'AT' => 'النمسا',
    'DE' => 'ألمانيا',
    'LU' => 'لوكسمبورغ',
    _ => code,
  };
  @override
  String statusChanged(String label, String status) =>
      'حالة $label الآن: $status';
  @override
  String statusFailed(String label) => 'لم يُحدَّث $label';
  @override
  String boardColumnSubtitle(OrderStatus status) => switch (status) {
    OrderStatus.paid => 'جاهزة للتجهيز',
    OrderStatus.picking => 'على طاولة العمل',
    OrderStatus.packed => 'بانتظار شركة الشحن',
    OrderStatus.shipped => 'لدى شركة الشحن',
    _ => '',
  };
  @override
  String get emptyColumn => 'لا شيء هنا';
  @override
  String moveFailed(String label) => 'تعذّر نقل $label، فعاد إلى مكانه.';
  @override
  String get breadcrumbOrders => 'الطلبات';
  @override
  String placedOn(String date) => 'طُلب في $date';
  @override
  String get shipAndEmail => 'الشحن وإبلاغ العميل بالبريد';
  @override
  String get shipAndEmailHint => 'يرسل رابط التتبّع';
  @override
  String get more => 'المزيد';
  @override
  String get refund => 'استرداد…';
  @override
  String get cancelOrder => 'إلغاء الطلب';
  @override
  String get items => 'القطع';
  @override
  String get summary => 'الملخّص';
  @override
  String get subtotal => 'المجموع الفرعي';
  @override
  String get shipping => 'الشحن';
  @override
  String get free => 'مجاني';
  @override
  String taxIncluded(String rate) => 'شامل ضريبة القيمة المضافة ($rate)';
  @override
  String get total => 'الإجمالي';
  @override
  String get refunded => 'المسترد';
  @override
  String get customer => 'العميل';
  @override
  String get shipTo => 'عنوان الشحن';
  @override
  String get payment => 'الدفع';
  @override
  String get channel => 'القناة';
  @override
  String get activity => 'السجل';
  @override
  String get notes => 'الملاحظات';
  @override
  String quantity(int qty) => '× $qty';
  @override
  String get eachPrice => 'للقطعة';
  @override
  String event(OrderEventKind kind) => switch (kind) {
    OrderEventKind.placed => 'تم الطلب',
    OrderEventKind.paid => 'تم استلام الدفعة',
    OrderEventKind.picking => 'بدأ التجهيز',
    OrderEventKind.packed => 'تم التغليف',
    OrderEventKind.shipped => 'سُلّم لشركة الشحن',
    OrderEventKind.delivered => 'تم التوصيل',
    OrderEventKind.cancelled => 'أُلغي',
    OrderEventKind.refunded => 'تم الاسترداد',
    OrderEventKind.note => 'ملاحظة',
    OrderEventKind.emailed => 'أُبلغ العميل بالبريد',
  };
  @override
  String byWhom(String name) => 'بواسطة $name';
  @override
  String get byCustomer => 'بواسطة العميل';
  @override
  String refundDetail(String amount, String reason) =>
      reason.isEmpty ? amount : '$amount · $reason';
  @override
  String updating(String label) => 'جارٍ تحديث $label…';
  @override
  String get orderNotFoundTitle => 'الطلب غير موجود';
  @override
  String orderNotFoundMessage(String label) =>
      'لا يوجد طلب $label. ربما كُتب الرقم خطأً.';
  @override
  String get backToOrders => 'العودة إلى الطلبات';
  @override
  String refundTitle(String label) => 'استرداد $label';
  @override
  String get refundDescription =>
      'يعود المبلغ بطريقة الدفع التي استخدمها العميل.';
  @override
  String get amount => 'المبلغ';
  @override
  String refundableHint(String amount) => 'يمكن استرداد ما يصل إلى $amount.';
  @override
  String get reason => 'السبب';
  @override
  String get reasonHint => 'وصل تالفًا';
  @override
  String get refundTooHigh => 'المبلغ أكبر مما تبقّى للاسترداد.';
  @override
  String get refundChanged =>
      'استردّ أحدهم جزءًا من هذا الطلب في هذه الأثناء. تحقّق من المبلغ وحاول مجددًا.';
  @override
  String get refundInvalid => 'أدخل مبلغًا أكبر من صفر.';
  @override
  String refundDone(String amount, String label) =>
      'تم استرداد $amount من $label';
  @override
  String get nothingToRefund => 'لم يبقَ شيء للاسترداد';
  @override
  String cancelTitle(String label) => 'إلغاء $label؟';
  @override
  String get cancelMessage =>
      'يُبلَّغ العميل ويخرج الطلب من قائمة الانتظار. لا يمكن التراجع عن ذلك.';
  @override
  String get keepOrder => 'الإبقاء على الطلب';
  @override
  String cancelled(String label) => 'أُلغي $label';
  @override
  String get noteLabel => 'إضافة ملاحظة';
  @override
  String get noteHint => 'الملاحظات للفريق فقط. اكتب @ لذكر زميل.';
  @override
  String get addNote => 'إضافة الملاحظة';
  @override
  String get noteAdded => 'أُضيفت الملاحظة';
  @override
  String get noNotes => 'لا ملاحظات بعد.';
  @override
  String get searchCustomers => 'الاسم أو البريد أو المدينة…';
  @override
  String get columnEmail => 'البريد الإلكتروني';
  @override
  String get columnCity => 'المدينة';
  @override
  String get columnTags => 'الوسوم';
  @override
  String get columnSince => 'عميل منذ';
  @override
  String get noCustomersTitle => 'لا يوجد عملاء بعد';
  @override
  String get noCustomersMessage => 'يظهر هنا كل من يطلب من المتجر.';
  @override
  String get customerDetails => 'التفاصيل';
  @override
  String get customerOrders => 'الطلبات';
  @override
  String get email => 'البريد الإلكتروني';
  @override
  String get city => 'المدينة';
  @override
  String get country => 'البلد';
  @override
  String get tags => 'الوسوم';
  @override
  String get noTags => 'لا شيء';
  @override
  String customerSummary(String name, int orders) => switch (orders) {
    0 => 'لم يطلب $name شيئًا بعد.',
    1 => 'قدّم $name طلبًا واحدًا.',
    2 => 'قدّم $name طلبين.',
    <= 10 => 'قدّم $name $orders طلبات.',
    _ => 'قدّم $name $orders طلبًا.',
  };
  @override
  String latestOrder(String label) => 'آخر طلب: $label';
  @override
  String get emailCustomer => 'كتابة بريد';
  @override
  String get noCustomerOrders => 'لا طلبات بعد.';
  @override
  String deleteViewTitle(String name) => 'حذف «$name»؟';
  @override
  String get deleteViewMessage =>
      'يفقده أيضًا من يستخدمه من الفريق. تبقى الطلبات كما هي.';
  @override
  String get deleteView => 'حذف العرض';
  @override
  String get refundAction => 'استرداد';
  @override
  String get awaitingPayment => 'بانتظار الدفع';
  @override
  String get paymentReceived => 'تم التحصيل';
  @override
  String get fullyRefunded => 'مستردّ';
  @override
  String place(String city, String country) => '$city، $country';
}
