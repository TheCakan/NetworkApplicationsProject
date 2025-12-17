# Description of Operation

## What the App Does

Currency exchange mobile app where users can:
- Create account and login
- View exchange rates (USD, EUR, GBP, PLN)
- Exchange currencies
- See transaction history
- Check account balance

## How It Works

**Backend (Node.js)**
- Runs on port 8080
- Handles user authentication
- Processes currency exchanges
- Stores data in MySQL database

**Frontend (Flutter)**
- Web: Connects to `localhost:8080`
- Android: Connects to `10.0.2.2:8080`
- Automatically detects platform

**Database (MySQL)**
- Stores user accounts
- Stores transactions
- Stores balances

## Flow

1. User registers/logs in
2. App fetches exchange rates from backend
3. User selects currencies and amount
4. Backend processes exchange
5. Database updates balances
6. Transaction saved to history

