import 'package:admin_ui/admin_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Illustrative version history for a marketing home page — three locales,
/// text + rich-body fields, every block op represented. The plain fields are
/// compared from v4's values and the draft's, the sections and the body are
/// authored as changes; the demo reuses the diff against any chosen base so
/// the rendering is the point, not the arithmetic.

const _you = Color(0xFF5b5bd6);
const _marina = Color(0xFF9333a8);
const _priya = Color(0xFF0f9d8f);

const draftRef = VersionRef(
  id: 'draft',
  label: 'Working draft',
  author: 'You',
  initials: 'YO',
  color: _you,
  timestamp: 'just now',
  status: VersionStatus.draft,
);

const versions = <VersionRef>[
  draftRef,
  VersionRef(
    id: 'v4',
    label: 'Trimmed intro, added CTA',
    author: 'Marina Cole',
    initials: 'MC',
    color: _marina,
    timestamp: '2 hours ago',
    status: VersionStatus.published,
    number: 4,
  ),
  VersionRef(
    id: 'v3',
    label: 'Reordered sections',
    author: 'You',
    initials: 'YO',
    color: _you,
    timestamp: 'yesterday',
    status: VersionStatus.published,
    number: 3,
  ),
  VersionRef(
    id: 'v2',
    label: 'Added testimonial',
    author: 'Priya Nair',
    initials: 'PN',
    color: _priya,
    timestamp: '3 days ago',
    status: VersionStatus.published,
    number: 2,
  ),
  VersionRef(
    id: 'v1',
    label: 'Initial publish',
    author: 'Marina Cole',
    initials: 'MC',
    color: _marina,
    timestamp: 'last week',
    status: VersionStatus.published,
    number: 1,
  ),
];

VersionRef versionById(String id) => versions.firstWhere((v) => v.id == id);

/// The page's own fields as v4 left them, the base of every diff here.
const _published = (
  title: {
    'en': 'Build faster with Acme',
    'fr': 'Construisez plus vite avec Acme',
    'nl': 'Bouw sneller met Acme',
  },
  slug: {
    'en': 'build-faster-with-acme',
    'fr': 'construisez-plus-vite',
    'nl': 'bouw-sneller-met-acme',
  },
  metaDescription: {
    'en': 'Acme helps engineering teams build and deploy software faster.',
    'fr': 'Acme aide les équipes à livrer plus vite.',
    'nl': 'Acme helpt teams sneller te leveren.',
  },
  code: 'MKTG-HOME',
);

/// The same fields in the working draft.
const _draft = (
  title: {
    'en': 'Ship faster with Acme Cloud',
    'fr': 'Construisez plus vite avec Acme',
    'nl': 'Bouw sneller met Acme Cloud',
  },
  slug: {
    'en': 'ship-faster-with-acme-cloud',
    'fr': 'construisez-plus-vite',
    'nl': 'bouw-sneller-met-acme',
  },
  metaDescription: {
    'en': 'Acme Cloud helps engineering teams build, test, and deploy software faster than ever.',
    'fr': 'Acme aide les équipes à livrer plus vite.',
    'nl': 'Acme helpt teams sneller te leveren.',
  },
  code: 'MKTG-HOME',
);

/// The page's fields, the plain ones compared from the two records; the
/// sections and the body carry their own record and block changes.
final _fields = <FieldDiff>[
  FieldDiff.translated('title', 'Title', _published.title, _draft.title),
  FieldDiff.translated('slug', 'Slug', _published.slug, _draft.slug),
  FieldDiff.translated(
    'metaDescription',
    'Meta description',
    _published.metaDescription,
    _draft.metaDescription,
  ),
  FieldDiff.scalar('code', 'Internal code', _published.code, _draft.code),
  sectionsDiff,
  FieldDiff(
    label: 'Body',
    fieldKey: 'body',
    kind: DiffFieldKind.richText,
    translatable: true,
    locales: [
      LocaleDiff(locale: 'en', op: DiffOp.changed, blocks: _enBody),
      LocaleDiff(locale: 'fr', op: DiffOp.changed, blocks: _frBody),
      LocaleDiff(locale: 'nl', op: DiffOp.changed, blocks: _nlBody),
    ],
  ),
];

/// An owned list of page sections: one edited, one moved, one added and one
/// removed, each keyed by its record id.
const sectionsDiff = FieldDiff(
  label: 'Sections',
  fieldKey: 'sections',
  kind: DiffFieldKind.recordList,
  locales: [],
  records: [
    RecordChange(
      id: 's1',
      op: DiffOp.changed,
      label: 'Pricing table',
      fields: [
        FieldDiff(
          label: 'Heading',
          fieldKey: 'heading',
          kind: DiffFieldKind.text,
          locales: [
            LocaleDiff(
              locale: '',
              op: DiffOp.changed,
              before: 'Simple plans',
              after: 'Simple, fair plans',
            ),
          ],
        ),
      ],
    ),
    RecordChange(
      id: 's2',
      op: DiffOp.moved,
      label: 'Customer logos',
      fromIndex: 3,
      toIndex: 1,
      fields: [],
    ),
    RecordChange(id: 's3', op: DiffOp.added, label: 'FAQ', fields: []),
    RecordChange(
      id: 's4',
      op: DiffOp.removed,
      label: 'Newsletter signup',
      fields: [],
    ),
  ],
);

/// The English body's block changes, every op represented.
const bodyBlocks = _enBody;

const _enBody = <BlockChange>[
  BlockChange(
    id: 'b1',
    type: 'heading_1',
    op: DiffOp.changed,
    before: 'Build faster',
    after: 'Ship faster',
  ),
  BlockChange(
    id: 'b2',
    type: 'paragraph',
    op: DiffOp.changed,
    before: 'Acme helps teams build and ship software in minutes, not weeks.',
    after: 'Acme Cloud helps teams build, test, and ship software in minutes, not weeks.',
  ),
  BlockChange(
    id: 'b3',
    type: 'paragraph',
    op: DiffOp.added,
    after: 'No credit card required to start your first project.',
  ),
  BlockChange(
    id: 'b4',
    type: 'quote',
    op: DiffOp.removed,
    before: '“Acme is the backbone of our entire release process.”',
  ),
  BlockChange(
    id: 'b5',
    type: 'heading_2',
    op: DiffOp.moved,
    before: 'Why teams choose us',
    after: 'Why teams choose us',
    fromIndex: 4,
    toIndex: 2,
  ),
  BlockChange(
    id: 'b6',
    type: 'paragraph',
    op: DiffOp.unchanged,
    before: 'Trusted by thousands of teams worldwide.',
    after: 'Trusted by thousands of teams worldwide.',
  ),
];

const _frBody = <BlockChange>[
  BlockChange(
    id: 'b2',
    type: 'paragraph',
    op: DiffOp.changed,
    before: 'Acme aide les équipes à concevoir et livrer en quelques minutes.',
    after: 'Acme Cloud aide les équipes à concevoir, tester et livrer en quelques minutes.',
  ),
];

const _nlBody = <BlockChange>[
  BlockChange(
    id: 'b1',
    type: 'heading_1',
    op: DiffOp.changed,
    before: 'Bouw sneller',
    after: 'Verzend sneller',
  ),
];

/// The diff shown in the demos — [baseId] swaps the BEFORE endpoint.
VersionDiff diffAgainst(String baseId) => VersionDiff.of(
  base: versionById(baseId),
  compare: draftRef,
  fields: _fields,
);
