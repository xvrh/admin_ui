// The one table the seed draws its words from. Everything here is invented
// or generic: plant, pot and tool nouns, common first and last names, and
// supplier names made up for this shop. No real brand, shop, person or
// domain appears; addresses end in example.com.

typedef Words = ({String en, String fr, String ar});

/// A category of the catalogue.
typedef CategoryWords = ({String id, String? parent, Words name, Words blurb});

const categoryWords = <CategoryWords>[
  (
    id: 'cat-01',
    parent: null,
    name: (en: 'Indoor plants', fr: 'Plantes d’intérieur', ar: 'نباتات داخلية'),
    blurb: (
      en: 'Easy-going and happy in bright, indirect light.',
      fr: 'Facile à vivre, aime la lumière vive et indirecte.',
      ar: 'سهلة العناية وتحب الضوء الساطع غير المباشر.',
    ),
  ),
  (
    id: 'cat-02',
    parent: 'cat-01',
    name: (en: 'Ferns', fr: 'Fougères', ar: 'سراخس'),
    blurb: (
      en: 'Loves humidity and a shady corner.',
      fr: 'Aime l’humidité et les coins ombragés.',
      ar: 'تحب الرطوبة والزوايا الظليلة.',
    ),
  ),
  (
    id: 'cat-03',
    parent: 'cat-01',
    name: (en: 'Succulents', fr: 'Plantes grasses', ar: 'نباتات عصارية'),
    blurb: (
      en: 'Needs little water and plenty of sun.',
      fr: 'Demande peu d’eau et beaucoup de soleil.',
      ar: 'تحتاج إلى القليل من الماء والكثير من الشمس.',
    ),
  ),
  (
    id: 'cat-04',
    parent: null,
    name: (
      en: 'Outdoor plants',
      fr: 'Plantes d’extérieur',
      ar: 'نباتات خارجية',
    ),
    blurb: (
      en: 'Hardy outdoors from spring to autumn.',
      fr: 'Rustique en extérieur du printemps à l’automne.',
      ar: 'تتحمل الأجواء الخارجية من الربيع إلى الخريف.',
    ),
  ),
  (
    id: 'cat-05',
    parent: null,
    name: (en: 'Pots', fr: 'Pots', ar: 'أصص'),
    blurb: (
      en: 'Made by hand, with a drainage hole.',
      fr: 'Fait main, avec un trou de drainage.',
      ar: 'مصنوع يدويًا مع فتحة تصريف.',
    ),
  ),
  (
    id: 'cat-06',
    parent: null,
    name: (en: 'Tools', fr: 'Outils', ar: 'أدوات'),
    blurb: (
      en: 'Built to last a lifetime of gardening.',
      fr: 'Conçu pour durer toute une vie de jardinage.',
      ar: 'مصمم ليدوم مدى الحياة في الحديقة.',
    ),
  ),
  (
    id: 'cat-07',
    parent: null,
    name: (en: 'Soil & care', fr: 'Terreau et soins', ar: 'تربة وعناية'),
    blurb: (
      en: 'Peat-free and ready to use.',
      fr: 'Sans tourbe et prêt à l’emploi.',
      ar: 'خالٍ من الخث وجاهز للاستخدام.',
    ),
  ),
  (
    id: 'cat-08',
    parent: null,
    name: (en: 'Seeds', fr: 'Graines', ar: 'بذور'),
    blurb: (
      en: 'Sow indoors in early spring.',
      fr: 'À semer à l’intérieur au début du printemps.',
      ar: 'تُزرع في الداخل في أوائل الربيع.',
    ),
  ),
];

/// The product nouns, each with its category. Index 11 is the Boston fern
/// the story edits (`p-12`).
const productWords = <(Words, String)>[
  ((en: 'Monstera', fr: 'Monstera', ar: 'مونستيرا'), 'cat-01'),
  ((en: 'Snake plant', fr: 'Sansevieria', ar: 'نبتة الثعبان'), 'cat-01'),
  ((en: 'Peace lily', fr: 'Spathiphyllum', ar: 'زنبق السلام'), 'cat-01'),
  ((en: 'Rubber plant', fr: 'Caoutchouc', ar: 'نبتة المطاط'), 'cat-01'),
  ((en: 'Pothos', fr: 'Pothos', ar: 'بوتس'), 'cat-01'),
  ((en: 'Fiddle-leaf fig', fr: 'Figuier lyre', ar: 'تين الكمان'), 'cat-01'),
  (
    (en: 'Spider plant', fr: 'Plante araignée', ar: 'النبتة العنكبوتية'),
    'cat-01',
  ),
  ((en: 'Maidenhair fern', fr: 'Capillaire', ar: 'سرخس كزبرة البئر'), 'cat-02'),
  (
    (en: 'Bird’s nest fern', fr: 'Fougère nid d’oiseau', ar: 'سرخس عش الطائر'),
    'cat-02',
  ),
  ((en: 'Staghorn fern', fr: 'Corne d’élan', ar: 'سرخس قرن الأيل'), 'cat-02'),
  (
    (
      en: 'Rabbit’s foot fern',
      fr: 'Fougère patte de lapin',
      ar: 'سرخس قدم الأرنب',
    ),
    'cat-02',
  ),
  ((en: 'Boston fern', fr: 'Fougère de Boston', ar: 'سرخس بوسطن'), 'cat-02'),
  ((en: 'Aloe vera', fr: 'Aloe vera', ar: 'صبار الألوفيرا'), 'cat-03'),
  ((en: 'Echeveria', fr: 'Echeveria', ar: 'إشيفيريا'), 'cat-03'),
  ((en: 'Jade plant', fr: 'Arbre de jade', ar: 'نبتة اليشم'), 'cat-03'),
  ((en: 'Haworthia', fr: 'Haworthia', ar: 'هاوورثيا'), 'cat-03'),
  (
    (en: 'String of pearls', fr: 'Collier de perles', ar: 'عقد اللؤلؤ'),
    'cat-03',
  ),
  ((en: 'Lavender', fr: 'Lavande', ar: 'خزامى'), 'cat-04'),
  ((en: 'Rosemary', fr: 'Romarin', ar: 'إكليل الجبل'), 'cat-04'),
  ((en: 'Olive tree', fr: 'Olivier', ar: 'شجرة زيتون'), 'cat-04'),
  ((en: 'Hydrangea', fr: 'Hortensia', ar: 'كوبية'), 'cat-04'),
  ((en: 'Climbing rose', fr: 'Rosier grimpant', ar: 'وردة متسلقة'), 'cat-04'),
  (
    (en: 'Terracotta pot', fr: 'Pot en terre cuite', ar: 'أصيص فخاري'),
    'cat-05',
  ),
  ((en: 'Glazed pot', fr: 'Pot émaillé', ar: 'أصيص مزجج'), 'cat-05'),
  ((en: 'Hanging planter', fr: 'Suspension', ar: 'أصيص معلق'), 'cat-05'),
  ((en: 'Window box', fr: 'Jardinière', ar: 'صندوق نافذة'), 'cat-05'),
  (
    (en: 'Self-watering pot', fr: 'Pot à réserve d’eau', ar: 'أصيص ذاتي الري'),
    'cat-05',
  ),
  ((en: 'Hand trowel', fr: 'Transplantoir', ar: 'مجرفة يدوية'), 'cat-06'),
  ((en: 'Pruning shears', fr: 'Sécateur', ar: 'مقص تقليم'), 'cat-06'),
  ((en: 'Watering can', fr: 'Arrosoir', ar: 'مرشة'), 'cat-06'),
  (
    (en: 'Garden gloves', fr: 'Gants de jardinage', ar: 'قفازات حدائق'),
    'cat-06',
  ),
  ((en: 'Plant mister', fr: 'Brumisateur', ar: 'بخاخ نباتات'), 'cat-06'),
  ((en: 'Potting soil', fr: 'Terreau', ar: 'تربة زراعية'), 'cat-07'),
  ((en: 'Cactus mix', fr: 'Terreau pour cactus', ar: 'خلطة الصبار'), 'cat-07'),
  ((en: 'Liquid feed', fr: 'Engrais liquide', ar: 'سماد سائل'), 'cat-07'),
  (
    (en: 'Orchid bark', fr: 'Écorce pour orchidées', ar: 'لحاء الأوركيد'),
    'cat-07',
  ),
  ((en: 'Basil seeds', fr: 'Graines de basilic', ar: 'بذور الريحان'), 'cat-08'),
  (
    (en: 'Sunflower seeds', fr: 'Graines de tournesol', ar: 'بذور دوار الشمس'),
    'cat-08',
  ),
  (
    (
      en: 'Wildflower mix',
      fr: 'Mélange de fleurs sauvages',
      ar: 'خليط أزهار برية',
    ),
    'cat-08',
  ),
  ((en: 'Tomato seeds', fr: 'Graines de tomate', ar: 'بذور الطماطم'), 'cat-08'),
];

/// Appended to a noun for the second, larger run of the catalogue.
const largeWord = (en: 'XL', fr: 'XL', ar: 'كبير');

const latinFirstNames = [
  'Amelia', 'Bruno', 'Chloé', 'Daniel', 'Elise', 'Felix', 'Greta', 'Hugo', //
  'Ines', 'Jonas', 'Klara', 'Luca', 'Maya', 'Nils', 'Olivia', 'Pablo',
  'Quentin', 'Rosa', 'Simon', 'Tara', 'Ugo', 'Vera', 'Wim', 'Xenia', 'Yann',
  'Zoé', 'Anton', 'Bea', 'Carl', 'Dora',
];

const latinLastNames = [
  'Andersen', 'Bauer', 'Castel', 'Dubois', 'Engel', 'Ferreira', 'Garnier', //
  'Hoffmann', 'Iversen', 'Jansen', 'Keller', 'Laurent', 'Moreau', 'Novak',
  'Olsen', 'Petit', 'Quinn', 'Roux', 'Schmidt', 'Torres', 'Unger', 'Vidal',
  'Weber', 'Young', 'Zeller', 'Almeida', 'Blanc', 'Costa', 'Dupont',
  'Eriksen',
];

const arabicFirstNames = [
  'ليلى', 'سارة', 'يوسف', 'عمر', 'مريم', 'خالد', 'نور', 'أحمد', 'هدى', //
  'كريم', 'سلمى', 'طارق', 'رنا', 'زياد', 'دينا', 'سامي', 'ياسمين', 'بلال',
  'هالة', 'فادي', 'منى', 'رامي', 'لينا', 'وليد', 'جنى', 'حسن', 'ريم', 'ماجد',
  'أمل', 'نادر',
];

const arabicLastNames = [
  'حداد', 'منصور', 'خوري', 'العلي', 'ناصر', 'سالم', 'الحسن', 'عيسى', //
  'يوسف', 'شاهين', 'قاسم', 'بكر', 'حمدان', 'عثمان', 'الخطيب', 'رزق', 'صالح',
  'جابر', 'عطية', 'فرح', 'زيدان', 'الشامي', 'حبيب', 'نجار', 'سعيد',
  'الأحمد', 'مراد', 'عوض', 'كامل', 'داود',
];

/// Latin transliterations of [arabicFirstNames] and [arabicLastNames], for
/// the email addresses of customers whose names are in Arabic script.
const arabicFirstLatin = [
  'layla', 'sara', 'youssef', 'omar', 'maryam', 'khaled', 'nour', 'ahmed', //
  'huda', 'karim', 'salma', 'tarek', 'rana', 'ziad', 'dina', 'sami', 'yasmin',
  'bilal', 'hala', 'fadi', 'mona', 'rami', 'lina', 'walid', 'jana', 'hasan',
  'reem', 'majed', 'amal', 'nader',
];

const arabicLastLatin = [
  'haddad', 'mansour', 'khoury', 'alali', 'nasser', 'salem', 'alhasan', //
  'issa', 'youssef', 'shaheen', 'kassem', 'bakr', 'hamdan', 'othman',
  'alkhatib', 'rizk', 'saleh', 'jaber', 'atiyeh', 'farah', 'zidan',
  'alshami', 'habib', 'najjar', 'said', 'alahmad', 'murad', 'awad', 'kamel',
  'daoud',
];

/// Cities with their country code.
const places = [
  ('Lyon', 'FR'), ('Bordeaux', 'FR'), ('Nantes', 'FR'), ('Lille', 'FR'), //
  ('Marseille', 'FR'), ('Ghent', 'BE'), ('Liège', 'BE'), ('Utrecht', 'NL'),
  ('Porto', 'PT'), ('Basel', 'CH'), ('Graz', 'AT'), ('Freiburg', 'DE'),
  ('Luxembourg', 'LU'), ('Montpellier', 'FR'), ('Rennes', 'FR'),
];

const streets = [
  'Rue des Tilleuls', 'Avenue des Platanes', 'Chemin du Moulin', //
  'Rue de la Serre', 'Allée des Roses', 'Rue du Verger', 'Quai des Fleurs',
  'Place du Marché',
];

/// Suppliers: (name, country, terms in days).
const supplierWords = [
  ('Northfield Growers', 'NL', 30),
  ('Brookside Nursery', 'BE', 45),
  ('Ashvale Pottery', 'PT', 30),
  ('Meadowline Tools', 'DE', 60),
  ('Greenfold Soils', 'FR', 30),
  ('Willowmere Seeds', 'FR', 14),
  ('Harrowgate Supply', 'AT', 45),
  ('Fernbank Wholesale', 'NL', 30),
];

/// Staff: (name, role name, status name, invitation token).
const staffWords = [
  ('Nora Lindqvist', 'owner', 'active', null),
  ('Samir Benali', 'manager', 'active', null),
  ('Elena Ruiz', 'manager', 'active', null),
  ('Tom Becker', 'staff', 'active', null),
  ('Hana Okada', 'staff', 'active', null),
  ('Karim Mansour', 'staff', 'active', null),
  ('Jules Moreau', 'viewer', 'active', null),
  ('Priya Raman', 'staff', 'invited', 'invite-7'),
  ('Leo Fontaine', 'viewer', 'invited', 'invite-old'),
];

/// Care instruction keys and a few values each, in English (the care table
/// is a key-value field the staff write in the source language).
const careWords = {
  'light': ['Bright, indirect', 'Full sun', 'Partial shade', 'Low light'],
  'water': ['Weekly', 'When the top soil is dry', 'Keep moist', 'Sparingly'],
  'humidity': ['High', 'Average', 'Low'],
};

/// Tags a product can carry.
const productTags = [
  'pet-safe', 'easy-care', 'air-purifying', 'gift', 'new', 'bestseller', //
  'handmade', 'organic',
];

/// The shelf-label colours products are marked with, as ARGB.
const labelColors = [
  0xFF2F7D4F, 0xFF4A7FB5, 0xFFC46A3C, 0xFFD9577B, 0xFF7C3AED, 0xFFB45309, //
];

/// What each bundled illustration shows. `assets/media/` holds three takes
/// of each: `NN.png` for subject NN (01 … 12), then `NN+12.png` (mirrored,
/// another backdrop) and `NN+24.png` (a close-up).
enum MediaSubject {
  leaf,
  pot,
  wateringCan,
  fern,
  cactus,
  trowel,
  seedPacket,
  sun,
  flower,
  soilSack,
  gloves,
  seedlingTray,
}

/// The subject of [productWords]' pictures, index for index.
const productSubjects = <MediaSubject>[
  // Indoor plants
  MediaSubject.leaf, MediaSubject.leaf, MediaSubject.flower, //
  MediaSubject.leaf, MediaSubject.leaf, MediaSubject.leaf, MediaSubject.leaf,
  // Ferns
  MediaSubject.fern, MediaSubject.fern, MediaSubject.fern, //
  MediaSubject.fern, MediaSubject.fern,
  // Succulents
  MediaSubject.cactus, MediaSubject.cactus, MediaSubject.cactus, //
  MediaSubject.cactus, MediaSubject.cactus,
  // Outdoor
  MediaSubject.flower, MediaSubject.seedlingTray, MediaSubject.sun, //
  MediaSubject.flower, MediaSubject.flower,
  // Pots
  MediaSubject.pot, MediaSubject.pot, MediaSubject.pot, //
  MediaSubject.pot, MediaSubject.pot,
  // Tools
  MediaSubject.trowel, MediaSubject.trowel, MediaSubject.wateringCan, //
  MediaSubject.gloves, MediaSubject.wateringCan,
  // Soil and care
  MediaSubject.soilSack, MediaSubject.soilSack, MediaSubject.soilSack, //
  MediaSubject.soilSack,
  // Seeds
  MediaSubject.seedPacket, MediaSubject.seedPacket, MediaSubject.seedPacket, //
  MediaSubject.seedPacket,
];

/// One photo of the media library: its subject, which take of it
/// (0 to 2), and its caption, which is also its alt text and its file name.
typedef MediaPhoto = ({MediaSubject subject, int take, Words caption});

/// The library's forty photos, in upload order. The ones marked `spare`
/// in the seed are on no product.
const mediaPhotos = <MediaPhoto>[
  (
    subject: MediaSubject.fern,
    take: 0,
    caption: (
      en: 'Fern on a shelf',
      fr: 'Fougère sur une étagère',
      ar: 'سرخس على رف',
    ),
  ),
  (
    subject: MediaSubject.pot,
    take: 0,
    caption: (
      en: 'Terracotta pot, 12 cm',
      fr: 'Pot en terre cuite, 12 cm',
      ar: 'أصيص فخاري، 12 سم',
    ),
  ),
  (
    subject: MediaSubject.leaf,
    take: 0,
    caption: (
      en: 'Houseplant leaves, close-up',
      fr: 'Feuilles de plante d’intérieur, gros plan',
      ar: 'أوراق نبتة منزلية عن قرب',
    ),
  ),
  (
    subject: MediaSubject.cactus,
    take: 0,
    caption: (
      en: 'Cactus on a sunny sill',
      fr: 'Cactus sur un rebord ensoleillé',
      ar: 'صبار على حافة نافذة مشمسة',
    ),
  ),
  (
    subject: MediaSubject.fern,
    take: 1,
    caption: (
      en: 'Fern in a hanging basket',
      fr: 'Fougère en suspension',
      ar: 'سرخس في سلة معلقة',
    ),
  ),
  (
    subject: MediaSubject.flower,
    take: 0,
    caption: (en: 'Flower in bloom', fr: 'Fleur épanouie', ar: 'زهرة متفتحة'),
  ),
  (
    subject: MediaSubject.wateringCan,
    take: 0,
    caption: (
      en: 'Watering can by the door',
      fr: 'Arrosoir près de la porte',
      ar: 'مرشة بجانب الباب',
    ),
  ),
  (
    subject: MediaSubject.leaf,
    take: 1,
    caption: (
      en: 'Leafy plant by a window',
      fr: 'Plante feuillue près d’une fenêtre',
      ar: 'نبتة ورقية قرب النافذة',
    ),
  ),
  (
    subject: MediaSubject.soilSack,
    take: 0,
    caption: (
      en: 'Bag of potting soil',
      fr: 'Sac de terreau',
      ar: 'كيس تربة زراعية',
    ),
  ),
  (
    subject: MediaSubject.fern,
    take: 2,
    caption: (
      en: 'Fern fronds, close-up',
      fr: 'Frondes de fougère, gros plan',
      ar: 'سعف السرخس عن قرب',
    ),
  ),
  (
    subject: MediaSubject.seedPacket,
    take: 0,
    caption: (
      en: 'Seed packet, front',
      fr: 'Sachet de graines, recto',
      ar: 'كيس بذور من الأمام',
    ),
  ),
  (
    subject: MediaSubject.cactus,
    take: 1,
    caption: (
      en: 'Succulents in a row',
      fr: 'Plantes grasses alignées',
      ar: 'نباتات عصارية في صف',
    ),
  ),
  (
    subject: MediaSubject.trowel,
    take: 0,
    caption: (
      en: 'Hand trowel in the soil',
      fr: 'Transplantoir planté dans la terre',
      ar: 'مجرفة يدوية في التربة',
    ),
  ),
  (
    subject: MediaSubject.pot,
    take: 1,
    caption: (
      en: 'Glazed pot on a bench',
      fr: 'Pot émaillé sur un établi',
      ar: 'أصيص مزجج على طاولة عمل',
    ),
  ),
  (
    subject: MediaSubject.leaf,
    take: 2,
    caption: (
      en: 'Tall houseplant in a corner',
      fr: 'Grande plante d’intérieur dans un coin',
      ar: 'نبتة منزلية طويلة في زاوية',
    ),
  ),
  (
    subject: MediaSubject.sun,
    take: 0,
    caption: (
      en: 'Olive tree in full sun',
      fr: 'Olivier en plein soleil',
      ar: 'شجرة زيتون تحت الشمس',
    ),
  ),
  (
    subject: MediaSubject.flower,
    take: 1,
    caption: (
      en: 'Flowering plant on a terrace',
      fr: 'Plante fleurie sur une terrasse',
      ar: 'نبتة مزهرة على شرفة',
    ),
  ),
  (
    subject: MediaSubject.gloves,
    take: 0,
    caption: (
      en: 'Garden gloves on a fence',
      fr: 'Gants de jardinage sur une clôture',
      ar: 'قفازات حدائق على سياج',
    ),
  ),
  (
    subject: MediaSubject.cactus,
    take: 2,
    caption: (
      en: 'Succulent rosette, close-up',
      fr: 'Rosette de plante grasse, gros plan',
      ar: 'وردة نبتة عصارية عن قرب',
    ),
  ),
  (
    subject: MediaSubject.seedlingTray,
    take: 0,
    caption: (
      en: 'Seedling tray on a sill',
      fr: 'Plateau de semis sur un rebord',
      ar: 'صينية شتلات على حافة النافذة',
    ),
  ),
  (
    subject: MediaSubject.fern,
    take: 0,
    caption: (
      en: 'Fern on a plant stand',
      fr: 'Fougère sur une sellette',
      ar: 'سرخس على حامل نباتات',
    ),
  ),
  (
    subject: MediaSubject.soilSack,
    take: 1,
    caption: (
      en: 'Soil mix on a potting bench',
      fr: 'Mélange de terreau sur un établi',
      ar: 'خلطة تربة على طاولة الزراعة',
    ),
  ),
  (
    subject: MediaSubject.wateringCan,
    take: 1,
    caption: (
      en: 'Metal watering can, side view',
      fr: 'Arrosoir en métal, vue de côté',
      ar: 'مرشة معدنية من الجانب',
    ),
  ),
  (
    subject: MediaSubject.pot,
    take: 2,
    caption: (
      en: 'Stack of nursery pots',
      fr: 'Pile de pots de culture',
      ar: 'كومة من أصص المشتل',
    ),
  ),
  (
    subject: MediaSubject.leaf,
    take: 1,
    caption: (
      en: 'Houseplant on a side table',
      fr: 'Plante d’intérieur sur une desserte',
      ar: 'نبتة منزلية على طاولة جانبية',
    ),
  ),
  (
    subject: MediaSubject.trowel,
    take: 1,
    caption: (
      en: 'Garden tools on a bench',
      fr: 'Outils de jardin sur un établi',
      ar: 'أدوات حديقة على طاولة عمل',
    ),
  ),
  (
    subject: MediaSubject.seedPacket,
    take: 1,
    caption: (
      en: 'Seed packets in a box',
      fr: 'Sachets de graines dans une boîte',
      ar: 'أكياس بذور في علبة',
    ),
  ),
  (
    subject: MediaSubject.flower,
    take: 2,
    caption: (
      en: 'Petals, close-up',
      fr: 'Pétales, gros plan',
      ar: 'بتلات عن قرب',
    ),
  ),
  (
    subject: MediaSubject.fern,
    take: 1,
    caption: (
      en: 'Young fern in a nursery pot',
      fr: 'Jeune fougère en pot de culture',
      ar: 'سرخس صغير في أصيص مشتل',
    ),
  ),
  (
    subject: MediaSubject.cactus,
    take: 0,
    caption: (
      en: 'Cactus in a terracotta pot',
      fr: 'Cactus en pot de terre cuite',
      ar: 'صبار في أصيص فخاري',
    ),
  ),
  (
    subject: MediaSubject.soilSack,
    take: 2,
    caption: (
      en: 'Bark and grit, close-up',
      fr: 'Écorce et gravier, gros plan',
      ar: 'لحاء وحصى عن قرب',
    ),
  ),
  (
    subject: MediaSubject.trowel,
    take: 2,
    caption: (
      en: 'Trowel handle, close-up',
      fr: 'Manche de transplantoir, gros plan',
      ar: 'مقبض المجرفة عن قرب',
    ),
  ),
  (
    subject: MediaSubject.seedlingTray,
    take: 1,
    caption: (
      en: 'Herb seedlings sprouting',
      fr: 'Semis d’herbes aromatiques',
      ar: 'شتلات أعشاب تنبت',
    ),
  ),
  (
    subject: MediaSubject.wateringCan,
    take: 2,
    caption: (
      en: 'Watering can spout, close-up',
      fr: 'Bec d’arrosoir, gros plan',
      ar: 'فوهة المرشة عن قرب',
    ),
  ),
  // The spares: on no product yet.
  (
    subject: MediaSubject.leaf,
    take: 0,
    caption: (
      en: 'Glossy leaves after watering',
      fr: 'Feuilles brillantes après l’arrosage',
      ar: 'أوراق لامعة بعد الري',
    ),
  ),
  (
    subject: MediaSubject.pot,
    take: 0,
    caption: (
      en: 'Planter on a windowsill',
      fr: 'Jardinière sur un rebord de fenêtre',
      ar: 'أصيص على حافة النافذة',
    ),
  ),
  (
    subject: MediaSubject.flower,
    take: 0,
    caption: (
      en: 'Cut flowers in a jar',
      fr: 'Fleurs coupées dans un bocal',
      ar: 'أزهار مقطوفة في برطمان',
    ),
  ),
  (
    subject: MediaSubject.gloves,
    take: 1,
    caption: (
      en: 'Pair of work gloves',
      fr: 'Paire de gants de travail',
      ar: 'زوج من قفازات العمل',
    ),
  ),
  (
    subject: MediaSubject.cactus,
    take: 1,
    caption: (
      en: 'Small succulent on a desk',
      fr: 'Petite plante grasse sur un bureau',
      ar: 'نبتة عصارية صغيرة على مكتب',
    ),
  ),
  (
    subject: MediaSubject.seedPacket,
    take: 2,
    caption: (
      en: 'Seeds poured into a hand',
      fr: 'Graines versées dans la main',
      ar: 'بذور في كف اليد',
    ),
  ),
];

/// How many of [mediaPhotos], at the end, are on no product.
const spareMediaPhotos = 6;
