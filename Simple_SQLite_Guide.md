# Simple SQLite Implementation Guide for MonMan App

## What You Need to Know

SQLite is just a local database that saves your app's data on the device. Think of it like a smart filing cabinet that organizes your information.

## How MonMan Uses SQLite

Our app uses SQLite to store:
- **Accounts** (Bank accounts, credit cards, etc.)
- **Transactions** (Money in/out records)
- **Categories** (Groups for organizing expenses)
- **Bills & Subscriptions** (Recurring payments)

## The Simple Setup Process

### 1. Add SQLite to Your App
In `pubspec.yaml`, we added:
```yaml
sqflite: ^2.3.0    # The SQLite package
path: ^1.8.3       # Helps find database files
```

### 2. Create the Database Helper
This is like hiring a database manager. The `DatabaseHelper` class:
- Creates your database file
- Sets up tables (like spreadsheet sheets)
- Provides methods to save/load data

### 3. How Data Flows in MonMan

**When you add an account:**
1. You fill out the form
2. App creates an `Account` object
3. `DatabaseHelper.insertAccount()` saves it to SQLite
4. The account appears in your accounts list

**When you view accounts:**
1. App calls `DatabaseHelper.getAccounts()`
2. SQLite returns all saved accounts
3. App displays them in the UI

## Key Files in Our Implementation

- **`models/account.dart`** - Defines what an account looks like
- **`services/database_helper.dart`** - Manages all database operations
- **`screens/accounts_screen.dart`** - Shows accounts and uses the database

## Why This Works Well

1. **Offline First** - Works without internet
2. **Fast** - Data loads instantly from device
3. **Private** - Your data never leaves your device
4. **Reliable** - SQLite is battle-tested and stable

## What Happens Behind the Scenes

1. **First App Launch**: Creates database file and empty tables
2. **Adding Data**: Converts your input into database format and saves
3. **Loading Data**: Retrieves from database and converts back to objects
4. **Updates/Deletes**: Modifies existing database records

## The Magic Methods

- `insert()` - Adds new records
- `query()` - Gets records back
- `update()` - Changes existing records  
- `delete()` - Removes records

## That's It!

You don't need to understand SQL syntax or complex database concepts. The `DatabaseHelper` class handles all the complicated parts. You just:

1. Call methods like `insertAccount(account)`
2. Get data back with `getAccounts()`
3. The rest happens automatically

The database file lives on your device and grows as you use the app. Everything is handled for you behind the scenes!