# ProGear Smart Bag

A Flutter application for the graduation project - Smart Bag with Bluetooth integration and Supabase backend.

## Branches
- **main**: Stable branch. Only the team lead merges here after review.
- **dev**: Development branch where all features are merged and tested.
- **feature/**: Each new feature should have its own branch (e.g., `feature/bluetooth`, `feature/register-page`).

1. Clone the repository:
   ```bash
   git clone https://github.com/hayamansour1/progear_smart_bag.git
   cd progear_smart_bag
```

2. Install dependencies:
   ```bash
    flutter pub get
```


3. Create a .env file (you will get the values from the team lead):
SUPABASE_URL=your-url
SUPABASE_ANON_KEY=your-key

4. Run the app:
   ```bash
    flutter run
```

Workflow

- Always start from the dev branch:
   ```bash
    git checkout dev
    git pull origin dev
    git checkout -b feature/feature-name
```


- After finishing your changes:
   ```bash
    git add .
    git commit -m "Describe your change"
    git push -u origin feature/feature-name
```


- Open a Pull Request from your feature branch to dev.

- After review, changes will be merged from dev to main.