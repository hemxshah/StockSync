# StockSync – Multi-Tenant Inventory, Pokes & Recount Tasks (Flutter + Firebase)

StockSync is a production-grade inventory and team management platform for small businesses.  
It combines multi-organization access control, real-time stock tracking, **low-stock “pokes”**, **recount tasks**, and **manager approvals** — all in a clean, fast Flutter (Material 3) experience powered by Firebase.

---

## ⭐ What Makes StockSync Different

- **Low-Stock Intelligence**: Every product has a `min_quantity`. When `quantity <= min_quantity`, the app auto-creates a **Poke** to alert responsible managers.
- **Human-in-the-Loop Tasks**: Employees can **manually poke** a manager, or managers can **assign recount tasks** to employees to verify on-shelf counts.
- **Task Lifecycle**: Pokes & recounts move through `pending → inprogress → resolved` (with **repoke escalation** if ignored).
- **Escalations**: If a poke isn’t acted on within **24 hours**, StockSync auto-**re-pokes** (sends a fresh alert) until it’s resolved.
- **Real-Time Routing**: AuthGate routes users directly to the right dashboard based on email verification, org membership, and role.
- **Multi-Tenant & Secure**: Strong Firestore rules and per-org scoping guarantee that data stays inside the organization.

---

## 🔐 Roles & Access

| Role      | Capabilities |
|----------|--------------|
| **Manager** | Create org, share invite code, approve join requests, create/edit products, assign recount tasks, act on pokes, view KPIs & logs. |
| **Employee** | View products, update counts via tasks, raise manual pokes, see their assigned work and history. |

---

## 🧭 End-to-End Workflows

### 1) Onboarding & Org Access
1. User signs up → verifies email.
2. **Manager** creates an organization → gets a unique 6-character invite code (copy/share).
3. **Employee** enters invite code → system creates `join_requests/{uid}` → **Manager** approves.
4. On approval, user doc updates (`role`, `org_id`) and user is immediately routed to the right dashboard.

### 2) Low-Stock Poke (Automatic)
1. A product’s `quantity` drops to or below its `min_quantity` (via recount or update).
2. StockSync auto-creates a **Poke** targeting the product’s assigned manager(s).
3. Managers see the poke on their dashboard and can:
   - **Mark In-Progress** (acknowledge),
   - **Resolve** (restocked / decision taken),
   - **Re-poke** (assign/notify another teammate).

### 3) Manual Poke (Employee-Initiated)
- Employees can raise a **manual Poke** if they notice low stock or anomalies.
- Manager receives notifications just like auto-pokes.

### 4) Recount Tasks (Manager → Employee)
1. Manager creates a **Recount Task** selecting one or more products.
2. Employee receives the task, physically counts items, and submits the new quantities.
3. Manager reviews & **applies** the updates. If the new quantity is still below threshold, a new **Poke** is created automatically.

### 5) Escalation Logic
- Any **Poke** not moved from `pending` within **24h** is **auto-repoked** (and notifies again) until resolved.
- Recount tasks can be **reassigned** if not completed in time.

---

## 🧱 Firestore Schema (Multi-Tenant)

users/{uid}
organizations/{orgId}
├─ join_requests/{uid}
├─ products/{productId}
├─ pokes/{pokeId}
├─ count_tasks/{taskId}
└─ stock_logs/{logId}


**users**
- `name`, `email`, `org_id`, `role` (`manager` | `employee` | `pending`), `userVerificationStatus`, `fcm_token`, timestamps.

**organizations**
- `name`, `invite_code`, `managers` (array of uids), timestamps.

**products**
- `name`, `description`, `sku`, `quantity`, `min_quantity`, `manager_id`, `image_url`, timestamps.

**pokes**
- `product_id`, `product_snapshot` (denormalized name/sku for fast UI), `creator_id` (auto/manual), `assigned_to`, `status` (`pending` | `inprogress` | `resolved` | `repoked`), `retry_count`, timestamps.

**count_tasks**
- `assignee_id`, `created_by`, `status` (`pending` | `inprogress` | `submitted` | `resolved`),  
  `products: [ { product_id, expected_quantity } ]`, `submission: [ { product_id, counted_quantity } ]`, timestamps.

**stock_logs**
- Immutable audit trail of stock mutations: `type` (`recount_apply` | `manual_adjust` | `restock`), `product_id`, `delta`, `from`, `to`, `by`, `source` (task/poke), timestamps.

---

## 🔒 Security & Data Isolation (Highlights)

- **Organization-Scoped Reads/Writes**: All product/poke/task documents live under `organizations/{orgId}` ensuring tenant isolation.
- **Join Requests**: `join_requests/{uid}` (doc id = uid) prevents duplicates and simplifies secure rules.
- **Manager Authority**: Only managers (listed in `org.managers`) can approve requests, change product data, or update user `org_id`/`role`.
- **Transactions**: Approval flow updates both `join_requests` and `users` atomically.
- **Indexes**: Composite indexes support queries like `status + created_at` for fast dashboards.

---

## 📲 Notifications

- **FCM push** + **Local notifications** for:
  - New join requests (to managers),
  - Pokes (auto/manual),
  - Recount task assignments,
  - Approvals/role changes (to users).
- Device tokens stored in `users/{uid}.fcm_token`.

---

## 🖥 UI Overview (Material 3)

- **Auth** → Signup / Login with email verification screen (resend + block until verified).
- **Org Setup** → Create or Join via invite code (with copy/share dialog).
- **Manager Dashboard** → KPI cards (Low-stock count, Pending pokes, Tasks due), recent activity, quick actions.
- **Products** → Searchable list, add/edit with image, manager assignment, min-quantity thresholds.
- **Pokes** → Filter by status, act (In-Progress / Resolve / Re-poke), escalation badges.
- **Tasks** → Manager assign; Employee view + submit counts.
- **Settings** → Invite code (copy/share), join requests list, logout (confirm).

---

## 🧪 Reliability Features

- **Optimistic UI** with rollback on failure for product edits.
- **Real-time streams** (snapshots) for pokes/tasks so dashboards always reflect current work.
- **Defensive handlers**: precise SnackBars and logs for Firestore errors (including permission/index hints).
- **Auditability**: every stock change writes a `stock_logs` record.

---

## ⚙️ Tech Stack

- **Flutter** (Material 3, animations, responsive)
- **Firebase**: Auth, Firestore, FCM, (Storage for product images)
- **State**: Provider (lightweight), StreamBuilders
- **Utilities**: `share_plus` for invite code sharing

---

## 🧩 Why This Matters (Business Impact)

- Prevents out-of-stock surprises with **automatic low-stock detection**.
- Reduces miscounts by assigning **recount tasks** and tracking submissions.
- Keeps managers informed with **escalations** and **real-time dashboards**.
- Ensures **data security** and **tenant isolation** with robust Firestore rules.
- Designed to be **fast, modern, and interview-ready**.

---

## ▶️ Getting Started (Dev)

1. Create a Firebase project and enable **Auth (Email/Password)** and **Firestore**.
2. Add platforms & download `firebase_options.dart` via FlutterFire CLI.
3. Run the app:
   ```bash
   flutter pub get
   flutter run
