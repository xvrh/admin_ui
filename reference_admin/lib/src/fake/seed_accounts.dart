// Test values for the fake shop's sign-in, and nothing else: there is no
// server, and these open nothing outside this app. The live sign-in page
// lists them as a dev hint.

/// The password every demo account takes.
const demoPassword = 'potting-shed';

/// Demo sign-ins, one per role, as (email, role name).
const demoAccounts = [
  ('owner@example.com', 'owner'),
  ('manager@example.com', 'manager'),
  ('staff@example.com', 'staff'),
  ('viewer@example.com', 'viewer'),
];

/// Wrong passwords in a row that lock an account.
const lockAfterAttempts = 5;
