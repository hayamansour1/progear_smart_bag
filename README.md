

# ProGear Smart Bag

A Flutter application for the graduation project - Smart Bag with Bluetooth integration and Supabase backend.

---

## 🔀 Branching Strategy

- **main** → Stable branch (only merged after review & testing).
- **dev** → Development branch (all features get merged here first).
- **feature/** → Each new feature in its own branch  
  _(e.g., `feature/bluetooth`, `feature/register-page`)_.

---

## 🚀 Getting Started

### 1. Clone the repository
```bash
git clone https://github.com/hayamansour1/progear_smart_bag.git
cd progear_smart_bag
````

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure environment variables

Create a `.env` file in the root directory (values provided by the team lead):

```
SUPABASE_URL=your-url
SUPABASE_ANON_KEY=your-key
```

### 4. Run the app

```bash
flutter run
```

---

## 📌 Workflow

* Always start from the `dev` branch:

```bash
git checkout dev
git pull origin dev
git checkout -b feature/feature-name
```

* After finishing your changes:

```bash
git add .
git commit -m "Describe your change"
git push -u origin feature/feature-name
```

* Open a **Pull Request** from your `feature/feature-name` → `dev`.

* After review and testing, changes will be merged from `dev` → `main`.
