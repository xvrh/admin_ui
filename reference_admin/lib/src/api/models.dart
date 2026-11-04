import 'package:collection/collection.dart';

/// Text in each of the shop's languages, keyed `en`, `fr`, `ar`. A language
/// with no entry is missing, not empty.
typedef Translated = Map<String, String>;

/// The languages the shop sells in, source first.
const shopLanguages = ['en', 'fr', 'ar'];

/// [text] in [language], else English, else any: what a list shows.
String inLanguage(Translated text, String language) =>
    text[language] ?? text['en'] ?? text.values.firstOrNull ?? '';

// ---------------------------------------------------------------------------
// Staff, roles and sessions

enum Role { owner, manager, staff, viewer }

enum Permission { editCatalogue, manageOrders, refund, manageTeam, manageShop }

/// What each role may do. The UI hides what a role may not do; the fake
/// refuses it with `ShopError.forbidden` all the same.
const rolePermissions = <Role, Set<Permission>>{
  Role.owner: {
    Permission.editCatalogue,
    Permission.manageOrders,
    Permission.refund,
    Permission.manageTeam,
    Permission.manageShop,
  },
  Role.manager: {
    Permission.editCatalogue,
    Permission.manageOrders,
    Permission.refund,
    Permission.manageShop,
  },
  Role.staff: {Permission.editCatalogue, Permission.manageOrders},
  Role.viewer: {},
};

extension RoleAccess on Role {
  bool can(Permission permission) =>
      rolePermissions[this]!.contains(permission);
}

enum StaffStatus { active, invited, deactivated }

class StaffMember {
  final String id;
  final String name;
  final String email;
  final Role role;
  final StaffStatus status;
  final DateTime? lastActiveAt;

  const StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.lastActiveAt,
  });

  StaffMember copyWith({
    String? name,
    Role? role,
    StaffStatus? status,
    DateTime? lastActiveAt,
  }) => StaffMember(
    id: id,
    name: name ?? this.name,
    email: email,
    role: role ?? this.role,
    status: status ?? this.status,
    lastActiveAt: lastActiveAt ?? this.lastActiveAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.name,
    'status': status.name,
    'lastActiveAt': lastActiveAt?.toIso8601String(),
  };
}

class Session {
  final String token;
  final StaffMember staff;

  /// The shop's name as it stood at sign-in: empty until setup names it.
  final String shopName;

  const Session({
    required this.token,
    required this.staff,
    required this.shopName,
  });

  Session copyWith({String? shopName}) =>
      Session(token: token, staff: staff, shopName: shopName ?? this.shopName);
}

class Invite {
  final String token;
  final String email;
  final String name;
  final Role role;
  final String invitedBy;
  final DateTime expiresAt;

  const Invite({
    required this.token,
    required this.email,
    required this.name,
    required this.role,
    required this.invitedBy,
    required this.expiresAt,
  });
}

// ---------------------------------------------------------------------------
// Preferences

enum AppearanceMode { system, light, dark }

enum Density { compact, standard, comfortable }

/// One staff member's appearance, stored by the shop so it follows them
/// from one device to the next.
class UserPrefs {
  final String? theme;
  final AppearanceMode mode;

  /// The accent seed as ARGB, or null for the theme's own primary.
  final int? accent;
  final Density density;

  /// A language tag, or null to follow the device.
  final String? locale;
  final bool reduceMotion;

  const UserPrefs({
    this.theme,
    this.mode = AppearanceMode.system,
    this.accent,
    this.density = Density.standard,
    this.locale,
    this.reduceMotion = false,
  });

  UserPrefs copyWith({
    String? theme,
    AppearanceMode? mode,
    int? Function()? accent,
    Density? density,
    String? Function()? locale,
    bool? reduceMotion,
  }) => UserPrefs(
    theme: theme ?? this.theme,
    mode: mode ?? this.mode,
    accent: accent != null ? accent() : this.accent,
    density: density ?? this.density,
    locale: locale != null ? locale() : this.locale,
    reduceMotion: reduceMotion ?? this.reduceMotion,
  );

  Map<String, Object?> toJson() => {
    'theme': theme,
    'mode': mode.name,
    'accent': accent,
    'density': density.name,
    'locale': locale,
    'reduceMotion': reduceMotion,
  };
}

// ---------------------------------------------------------------------------
// Catalogue

enum ProductStatus { draft, active, archived }

class Category {
  final String id;
  final Translated name;
  final String? parentId;
  const Category({required this.id, required this.name, this.parentId});
}

class Supplier {
  final String id;
  final String name;
  final String email;
  final String country;

  /// Payment terms in days.
  final int terms;

  const Supplier({
    required this.id,
    required this.name,
    required this.email,
    required this.country,
    required this.terms,
  });
}

class Variant {
  final String size;
  final String skuSuffix;
  final int priceDeltaCents;
  final int stock;

  const Variant({
    required this.size,
    required this.skuSuffix,
    required this.priceDeltaCents,
    required this.stock,
  });

  Map<String, Object?> toJson() => {
    'size': size,
    'skuSuffix': skuSuffix,
    'priceDeltaCents': priceDeltaCents,
    'stock': stock,
  };

  @override
  bool operator ==(Object other) =>
      other is Variant &&
      other.size == size &&
      other.skuSuffix == skuSuffix &&
      other.priceDeltaCents == priceDeltaCents &&
      other.stock == stock;

  @override
  int get hashCode => Object.hash(size, skuSuffix, priceDeltaCents, stock);
}

/// A photo's framing: the kept rectangle and the focal point as fractions of
/// the image, and the turns and flips applied before them.
class PhotoCrop {
  final double left;
  final double top;
  final double right;
  final double bottom;
  final (double, double)? focal;
  final int quarterTurns;
  final bool flipH;
  final bool flipV;
  final double angle;

  const PhotoCrop({
    this.left = 0,
    this.top = 0,
    this.right = 1,
    this.bottom = 1,
    this.focal,
    this.quarterTurns = 0,
    this.flipH = false,
    this.flipV = false,
    this.angle = 0,
  });

  Map<String, Object?> toJson() => {
    'rect': [left, top, right, bottom],
    if (focal case (final x, final y)) 'focal': [x, y],
    'quarterTurns': quarterTurns,
    'flipH': flipH,
    'flipV': flipV,
    'angle': angle,
  };

  @override
  bool operator ==(Object other) =>
      other is PhotoCrop &&
      other.left == left &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom &&
      other.focal == focal &&
      other.quarterTurns == quarterTurns &&
      other.flipH == flipH &&
      other.flipV == flipV &&
      other.angle == angle;

  @override
  int get hashCode => Object.hash(
    left,
    top,
    right,
    bottom,
    focal,
    quarterTurns,
    flipH,
    flipV,
    angle,
  );
}

class Product {
  final String id;
  final String sku;
  final Translated name;
  final Translated description;
  final String categoryId;
  final List<String> tags;
  final int priceCents;
  final int? compareAtCents;
  final int stock;
  final int lowStockAt;
  final ProductStatus status;
  final bool featured;
  final DateTime? availableFrom;

  /// The shelf label's colour, as ARGB.
  final int labelColor;

  /// Care instructions: `light`, `water`, … to a short value.
  final Map<String, String> care;
  final List<Variant> variants;
  final List<String> photoIds;

  /// How each photo is framed, by asset id; a photo shown whole has none.
  final Map<String, PhotoCrop> photoCrops;
  final String supplierId;
  final int revision;
  final DateTime updatedAt;
  final String updatedBy;

  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.tags,
    required this.priceCents,
    this.compareAtCents,
    required this.stock,
    required this.lowStockAt,
    required this.status,
    required this.featured,
    this.availableFrom,
    required this.labelColor,
    required this.care,
    required this.variants,
    required this.photoIds,
    this.photoCrops = const {},
    required this.supplierId,
    required this.revision,
    required this.updatedAt,
    required this.updatedBy,
  });

  bool get isLowStock => stock <= lowStockAt;

  /// The shop languages [name] or [description] lacks.
  List<String> get missingLanguages => [
    for (final language in shopLanguages)
      if (!name.containsKey(language) || !description.containsKey(language))
        language,
  ];

  Product copyWith({
    String? sku,
    Translated? name,
    Translated? description,
    String? categoryId,
    List<String>? tags,
    int? priceCents,
    int? Function()? compareAtCents,
    int? stock,
    int? lowStockAt,
    ProductStatus? status,
    bool? featured,
    DateTime? Function()? availableFrom,
    int? labelColor,
    Map<String, String>? care,
    List<Variant>? variants,
    List<String>? photoIds,
    Map<String, PhotoCrop>? photoCrops,
    String? supplierId,
    int? revision,
    DateTime? updatedAt,
    String? updatedBy,
  }) => Product(
    id: id,
    sku: sku ?? this.sku,
    name: name ?? this.name,
    description: description ?? this.description,
    categoryId: categoryId ?? this.categoryId,
    tags: tags ?? this.tags,
    priceCents: priceCents ?? this.priceCents,
    compareAtCents: compareAtCents != null
        ? compareAtCents()
        : this.compareAtCents,
    stock: stock ?? this.stock,
    lowStockAt: lowStockAt ?? this.lowStockAt,
    status: status ?? this.status,
    featured: featured ?? this.featured,
    availableFrom: availableFrom != null ? availableFrom() : this.availableFrom,
    labelColor: labelColor ?? this.labelColor,
    care: care ?? this.care,
    variants: variants ?? this.variants,
    photoIds: photoIds ?? this.photoIds,
    photoCrops: photoCrops ?? this.photoCrops,
    supplierId: supplierId ?? this.supplierId,
    revision: revision ?? this.revision,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'sku': sku,
    'name': name,
    'description': description,
    'categoryId': categoryId,
    'tags': tags,
    'priceCents': priceCents,
    'compareAtCents': compareAtCents,
    'stock': stock,
    'lowStockAt': lowStockAt,
    'status': status.name,
    'featured': featured,
    'availableFrom': availableFrom?.toIso8601String(),
    'labelColor': labelColor,
    'care': care,
    'variants': [for (final v in variants) v.toJson()],
    'photoIds': photoIds,
    if (photoCrops.isNotEmpty)
      'photoCrops': {
        for (final MapEntry(:key, :value) in photoCrops.entries)
          key: value.toJson(),
      },
    'supplierId': supplierId,
    'revision': revision,
    'updatedAt': updatedAt.toIso8601String(),
    'updatedBy': updatedBy,
  };
}

/// What `createProduct` takes: the fields the new-product form asks for.
class ProductDraft {
  final String sku;
  final Translated name;
  final String categoryId;
  final int priceCents;
  final int stock;
  final ProductStatus status;

  const ProductDraft({
    required this.sku,
    required this.name,
    required this.categoryId,
    required this.priceCents,
    this.stock = 0,
    this.status = ProductStatus.draft,
  });
}

class ProductRevision {
  final String productId;
  final int version;
  final DateTime at;
  final String by;
  final Product snapshot;

  const ProductRevision({
    required this.productId,
    required this.version,
    required this.at,
    required this.by,
    required this.snapshot,
  });
}

// ---------------------------------------------------------------------------
// Customers and orders

class Customer {
  final String id;
  final String name;
  final String email;
  final String city;
  final String country;
  final List<String> tags;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.city,
    required this.country,
    required this.tags,
    required this.createdAt,
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'city': city,
    'country': country,
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
  };
}

enum OrderStatus {
  pending,
  paid,
  picking,
  packed,
  shipped,
  delivered,
  cancelled;

  /// Paid for, and not yet handed to the carrier.
  bool get toShip => this == paid || this == picking || this == packed;

  /// Whether an order may go from this status to [next]: payment moves a
  /// pending order on; the fulfilment steps go either way until shipping;
  /// a shipped order can only be delivered; cancelling is for before it
  /// ships; delivered and cancelled are final.
  bool canBecome(OrderStatus next) => switch (this) {
    _ when next == this => true,
    pending => next == paid || next == cancelled,
    paid || picking || packed => next != pending && next != delivered,
    shipped => next == delivered,
    delivered || cancelled => false,
  };
}

enum PaymentMethod { card, bankTransfer }

enum OrderChannel { online, marketStall, wholesale }

class OrderLine {
  final String productId;

  /// The product's name and SKU when it was ordered, as a shop keeps them on
  /// the order: a later rename or deletion does not rewrite it.
  final Translated productName;
  final String sku;

  /// The media id of the product's cover photo when it was ordered, or null
  /// when it had none.
  final String? photoId;

  /// The variant's size, or null for the product itself.
  final String? variant;
  final int qty;
  final int unitCents;

  const OrderLine({
    required this.productId,
    required this.productName,
    required this.sku,
    this.photoId,
    this.variant,
    required this.qty,
    required this.unitCents,
  });

  /// A line for [product] at its current price.
  OrderLine.of(
    Product product, {
    this.variant,
    required this.qty,
    int? unitCents,
  }) : productId = product.id,
       productName = product.name,
       sku = product.sku,
       photoId = product.photoIds.firstOrNull,
       unitCents = unitCents ?? product.priceCents;

  int get totalCents => qty * unitCents;

  Map<String, Object?> toJson() => {
    'productId': productId,
    'productName': productName,
    'sku': sku,
    'photoId': photoId,
    'variant': variant,
    'qty': qty,
    'unitCents': unitCents,
  };
}

class Address {
  final String name;
  final String line1;
  final String postcode;
  final String city;
  final String country;

  const Address({
    required this.name,
    required this.line1,
    required this.postcode,
    required this.city,
    required this.country,
  });

  Map<String, Object?> toJson() => {
    'name': name,
    'line1': line1,
    'postcode': postcode,
    'city': city,
    'country': country,
  };
}

enum OrderEventKind {
  placed,
  paid,
  picking,
  packed,
  shipped,
  delivered,
  cancelled,
  refunded,
  note,
  emailed,
}

class OrderEvent {
  final OrderEventKind kind;
  final DateTime at;

  /// Who did it: a staff member's name, or null for the customer or system.
  final String? by;

  /// The note's text (with mention tokens), a refund's amount and reason.
  final String? detail;

  const OrderEvent({
    required this.kind,
    required this.at,
    this.by,
    this.detail,
  });

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'at': at.toIso8601String(),
    'by': by,
    'detail': detail,
  };
}

class Order {
  /// The customer-facing number, shown as `#1042`.
  final int number;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final DateTime placedAt;
  final OrderStatus status;
  final PaymentMethod payment;
  final OrderChannel channel;
  final int refundedCents;
  final bool refundRequested;
  final List<OrderLine> lines;
  final int shippingCents;
  final Address shipTo;
  final List<OrderEvent> events;

  /// Notes, oldest first, in the kit's mention-token form.
  final List<String> notes;

  const Order({
    required this.number,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.placedAt,
    required this.status,
    required this.payment,
    required this.channel,
    this.refundedCents = 0,
    this.refundRequested = false,
    required this.lines,
    required this.shippingCents,
    required this.shipTo,
    required this.events,
    this.notes = const [],
  });

  String get label => '#$number';

  int get subtotalCents => lines.fold(0, (sum, l) => sum + l.totalCents);
  int get totalCents => subtotalCents + shippingCents;

  /// The VAT included in [totalCents] at [taxRatePercent].
  int taxCents([int taxRatePercent = 20]) =>
      (totalCents * taxRatePercent / (100 + taxRatePercent)).round();

  int get refundableCents => totalCents - refundedCents;
  bool get partiallyRefunded => refundedCents > 0 && refundedCents < totalCents;
  int get itemCount => lines.fold(0, (sum, l) => sum + l.qty);

  Order copyWith({
    OrderStatus? status,
    int? refundedCents,
    bool? refundRequested,
    List<OrderEvent>? events,
    List<String>? notes,
  }) => Order(
    number: number,
    customerId: customerId,
    customerName: customerName,
    customerEmail: customerEmail,
    placedAt: placedAt,
    status: status ?? this.status,
    payment: payment,
    channel: channel,
    refundedCents: refundedCents ?? this.refundedCents,
    refundRequested: refundRequested ?? this.refundRequested,
    lines: lines,
    shippingCents: shippingCents,
    shipTo: shipTo,
    events: events ?? this.events,
    notes: notes ?? this.notes,
  );

  Map<String, Object?> toJson() => {
    'number': number,
    'customerId': customerId,
    'placedAt': placedAt.toIso8601String(),
    'status': status.name,
    'payment': payment.name,
    'channel': channel.name,
    'refundedCents': refundedCents,
    'refundRequested': refundRequested,
    'lines': [for (final l in lines) l.toJson()],
    'shippingCents': shippingCents,
    'shipTo': shipTo.toJson(),
    'events': [for (final e in events) e.toJson()],
    'notes': notes,
  };
}

// ---------------------------------------------------------------------------
// Dashboard

enum DashboardRange {
  days7(7),
  days30(30),
  days90(90);

  final int days;
  const DashboardRange(this.days);
}

class TopProduct {
  final String productId;
  final Translated name;
  final int units;
  final int revenueCents;

  const TopProduct({
    required this.productId,
    required this.name,
    required this.units,
    required this.revenueCents,
  });
}

/// What needs someone's attention today.
class AttentionCounts {
  final int toShip;
  final int lowStock;
  final int missingTranslations;
  final int refundRequests;

  const AttentionCounts({
    required this.toShip,
    required this.lowStock,
    required this.missingTranslations,
    required this.refundRequests,
  });
}

class DashboardStats {
  final DashboardRange range;

  /// Revenue net of refunds, cancelled orders left out.
  final int revenueCents;
  final int orders;
  final int averageOrderCents;
  final int newCustomers;

  /// The same four over the period before, for the deltas.
  final int previousRevenueCents;
  final int previousOrders;
  final int previousAverageOrderCents;
  final int previousNewCustomers;

  /// One value per day of the range, oldest first.
  final List<int> revenueSeries;
  final List<int> ordersSeries;
  final List<int> customersSeries;
  final List<TopProduct> topProducts;

  /// Orders per channel over the range.
  final Map<OrderChannel, int> channels;
  final AttentionCounts attention;

  const DashboardStats({
    required this.range,
    required this.revenueCents,
    required this.orders,
    required this.averageOrderCents,
    required this.newCustomers,
    required this.previousRevenueCents,
    required this.previousOrders,
    required this.previousAverageOrderCents,
    required this.previousNewCustomers,
    required this.revenueSeries,
    required this.ordersSeries,
    required this.customersSeries,
    required this.topProducts,
    required this.channels,
    required this.attention,
  });

  /// A shop with nothing sold yet.
  bool get isEmpty => orders == 0 && previousOrders == 0;
}

// ---------------------------------------------------------------------------
// Notifications, the frame's badges, search

enum NotificationKind { lowStock, newOrder, refundRequest, mention, system }

/// One inbox row. The frame words it from [kind] and [subject] in the app's
/// language, so a row reads right in French too.
class AppNotification {
  final String id;
  final NotificationKind kind;

  /// What it is about: a product name, an order label, a teammate's note.
  final Translated subject;

  /// Who caused it, for a mention.
  final String? actor;
  final DateTime at;
  final bool read;

  /// The app path it opens, such as `/orders/1042`.
  final String route;

  const AppNotification({
    required this.id,
    required this.kind,
    required this.subject,
    this.actor,
    required this.at,
    required this.read,
    required this.route,
  });

  AppNotification copyWith({String? id, bool? read}) => AppNotification(
    id: id ?? this.id,
    kind: kind,
    subject: subject,
    actor: actor,
    at: at,
    read: read ?? this.read,
    route: route,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'subject': subject,
    'actor': actor,
    'at': at.toIso8601String(),
    'read': read,
    'route': route,
  };
}

/// The counts the navigation shows beside its items.
class NavBadges {
  final int toShip;
  final int unreadNotifications;
  const NavBadges({required this.toShip, required this.unreadNotifications});
}

class SearchHits {
  final List<Order> orders;
  final List<Product> products;
  final List<Customer> customers;

  const SearchHits({
    this.orders = const [],
    this.products = const [],
    this.customers = const [],
  });

  bool get isEmpty => orders.isEmpty && products.isEmpty && customers.isEmpty;
}

// ---------------------------------------------------------------------------
// Shop settings

class ShippingZone {
  final String name;
  final List<String> countries;
  final int rateCents;

  const ShippingZone({
    required this.name,
    required this.countries,
    required this.rateCents,
  });

  Map<String, Object?> toJson() => {
    'name': name,
    'countries': countries,
    'rateCents': rateCents,
  };

  @override
  bool operator ==(Object other) =>
      other is ShippingZone &&
      other.name == name &&
      const ListEquality<String>().equals(other.countries, countries) &&
      other.rateCents == rateCents;

  @override
  int get hashCode => Object.hash(name, Object.hashAll(countries), rateCents);
}

class ShopSettings {
  final String name;
  final String supportEmail;
  final String currency;
  final double taxRatePercent;
  final List<String> languages;
  final List<ShippingZone> shippingZones;
  final bool setupComplete;

  const ShopSettings({
    required this.name,
    required this.supportEmail,
    required this.currency,
    required this.taxRatePercent,
    required this.languages,
    required this.shippingZones,
    required this.setupComplete,
  });

  static const blank = ShopSettings(
    name: '',
    supportEmail: '',
    currency: 'EUR',
    taxRatePercent: 20,
    languages: ['en'],
    shippingZones: [],
    setupComplete: false,
  );

  ShopSettings copyWith({
    String? name,
    String? supportEmail,
    String? currency,
    double? taxRatePercent,
    List<String>? languages,
    List<ShippingZone>? shippingZones,
    bool? setupComplete,
  }) => ShopSettings(
    name: name ?? this.name,
    supportEmail: supportEmail ?? this.supportEmail,
    currency: currency ?? this.currency,
    taxRatePercent: taxRatePercent ?? this.taxRatePercent,
    languages: languages ?? this.languages,
    shippingZones: shippingZones ?? this.shippingZones,
    setupComplete: setupComplete ?? this.setupComplete,
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'supportEmail': supportEmail,
    'currency': currency,
    'taxRatePercent': taxRatePercent,
    'languages': languages,
    'shippingZones': [for (final z in shippingZones) z.toJson()],
    'setupComplete': setupComplete,
  };
}

// ---------------------------------------------------------------------------
// Realtime

sealed class ShopEvent {
  const ShopEvent();
}

/// An order was placed on the storefront.
final class NewOrderEvent extends ShopEvent {
  final Order order;
  const NewOrderEvent(this.order);
}

/// A product fell to its low-stock threshold.
final class StockLowEvent extends ShopEvent {
  final Product product;
  const StockLowEvent(this.product);
}

/// A notification arrived for the signed-in staff member.
final class NotificationEvent extends ShopEvent {
  final AppNotification notification;
  const NotificationEvent(this.notification);
}

/// Orders changed on the server, by this session or another.
final class OrdersChangedEvent extends ShopEvent {
  final List<int> numbers;
  const OrdersChangedEvent(this.numbers);
}
