require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const axios = require('axios');
const db = require('./config/db'); // MySQL Connection Pool

const app = express();
const PORT = process.env.PORT || 8080;
const JWT_SECRET = process.env.JWT_SECRET;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Database Connection Check
async function initializeDB() {
  try {
    // We assume tables are already created via SQL script manually.
    // Just checking the connection here.
    await db.getConnection();
    console.log('MySQL Connection Successful!');
  } catch (err) {
    console.error('MySQL Connection Error:', err.message);
    process.exit(1);
  }
}

initializeDB();

// --- HELPER FUNCTIONS ---

// Helper: Fetch current rates from NBP (National Bank of Poland)
async function getExchangeRates() {
  try {
    const response = await axios.get('https://api.nbp.pl/api/exchangerates/tables/A/?format=json');  
    const rates = response.data[0].rates;
    const exchangeRates = { PLN: 1.0 };

    rates.forEach(rate => {
      if (['USD', 'EUR', 'GBP'].includes(rate.code)) {
        exchangeRates[rate.code] = rate.mid;
      }
    });
    return exchangeRates;
  } catch (error) {
    console.error('NBP API Error, using fallback rates.');
    return { PLN: 1.0, USD: 4.0, EUR: 4.3, GBP: 5.1 };
  }
}

// Helper: Fetch historical rates (Last X days)
async function getHistoricalRates(days = 30) {
  try {
    const response = await axios.get(
      `https://api.nbp.pl/api/exchangerates/tables/a/last/${days}/?format=json`
    );

    const historicalData = response.data.map(day => {
      const rates = { PLN: 1.0, date: day.effectiveDate };
      day.rates.forEach(rate => {
        if (['USD', 'EUR', 'GBP'].includes(rate.code)) {
          rates[rate.code] = rate.mid;
        }
      });
      return rates;
    });

    return historicalData.reverse(); // Newest first
  } catch (error) {
    console.error('Historical rates error:', error.message);
    return { error: 'Historical rates unavailable at the moment.' };
  }
}

// Middleware: Authenticate JWT Token
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  
  if (!token) return res.status(401).json({ error: 'Token required' });

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ error: 'Invalid token' });
    req.user = user;
    next();
  });
}

// --- ROUTES ---

// 1. Status Check
app.get('/api', (req, res) => res.json({ message: 'API is running - MySQL Active!' }));

// 2. Register User
app.post('/api/register', async (req, res) => {
  const connection = await db.getConnection();
  try {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ error: 'All fields are required' });
    }
    if (password.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters long' });
    }

    // Check if user exists
    const [existingUsers] = await connection.execute('SELECT id FROM Users WHERE email = ?', [email]);
    if (existingUsers.length > 0) {
      return res.status(400).json({ error: 'Email already registered' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insert User
    const [userResult] = await connection.execute(
      'INSERT INTO Users (name, email, password) VALUES (?, ?, ?)',
      [name, email, hashedPassword]
    );
    const userId = userResult.insertId;

    // Create Initial Wallet
    await connection.execute(
      'INSERT INTO Wallets (userId, PLN, USD, EUR, GBP) VALUES (?, ?, ?, ?, ?)',
      [userId, 1000.00, 0.00, 0.00, 0.00]
    );

    // Generate Token
    const token = jwt.sign({ id: userId, email: email }, JWT_SECRET, { expiresIn: '24h' });

    res.status(201).json({
      message: 'Registration successful',
      token,
      user: { id: userId, name: name, email: email }
    });
  } catch (err) {
    console.error('Register Error:', err);
    res.status(500).json({ error: 'Server error during registration' });
  } finally {
    if (connection) connection.release();
  }
});

// 3. Login User
app.post('/api/login', async (req, res) => {
  const connection = await db.getConnection();
  try {
    const { email, password } = req.body;

    // Find User
    const [users] = await connection.execute('SELECT id, name, email, password FROM Users WHERE email = ?', [email]);
    const user = users[0];

    if (!user) return res.status(401).json({ error: 'Invalid email or password' });

    // Verify Password
    const valid = await bcrypt.compare(password, user.password);
    if (!valid) return res.status(401).json({ error: 'Invalid email or password' });

    // Generate Token
    const token = jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, { expiresIn: '24h' });    

    res.json({
      message: 'Login successful',
      token,
      user: { id: user.id, name: user.name, email: user.email }
    });
  } catch (err) {
    console.error('Login Error:', err);
    res.status(500).json({ error: 'Server error during login' });
  } finally {
    if (connection) connection.release();
  }
});

// 4. Get Wallet Balance
app.get('/api/balance', authenticateToken, async (req, res) => {
    const userId = req.user.id;
    const connection = await db.getConnection();
    try {
        const [wallet] = await connection.execute(
            'SELECT PLN, USD, EUR, GBP FROM Wallets WHERE userId = ?',
            [userId]
        );

        if (wallet.length === 0) {
            return res.status(404).json({ error: 'Wallet not found' });
        }

        res.json({
            message: 'Current balances retrieved',
            balances: wallet[0]
        });
    } catch (err) {
        console.error('Balance Error:', err);
        res.status(500).json({ error: 'Failed to retrieve balance' });
    } finally {
        if (connection) connection.release();
    }
});

// 5. Add Funds (Simulated)
app.post('/api/addfunds', authenticateToken, async (req, res) => {
    const userId = req.user.id;
    const { amount } = req.body;
    const fundingCurrency = 'PLN';

    if (!amount || amount <= 0) {
        return res.status(400).json({ error: 'Invalid funding amount' });
    }

    let connection;
    try {
        connection = await db.getConnection();
        await connection.beginTransaction();

        // Add funds to PLN
        await connection.execute(
            'UPDATE Wallets SET PLN = PLN + ? WHERE userId = ?',
            [amount, userId]
        );

        // Record Transaction
        await connection.execute(
            'INSERT INTO Transactions (userId, type, fromCurrency, toCurrency, fromAmount, toAmount, rate) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [userId, 'FUND', fundingCurrency, fundingCurrency, amount, amount, 1.0]
        );

        await connection.commit();
        res.json({ message: 'Funds added successfully', currency: fundingCurrency, amount: parseFloat(amount) });
    } catch (err) {
        if (connection) await connection.rollback();
        console.error('Add Funds Error:', err);
        res.status(500).json({ error: 'Failed to process funding' });
    } finally {
        if (connection) connection.release();
    }
}); // Add Funds endpoint

// 6. Currency Exchange (Atomic Transaction) - FIXED VERSION
app.post('/api/exchange', authenticateToken, async (req, res) => {
  const connection = await db.getConnection();
  
  try {
    const { fromCurrency, toCurrency, amount } = req.body;
    const userId = req.user.id;

    // VALIDATION
    if (!fromCurrency || !toCurrency || !amount || amount <= 0) {
      return res.status(400).json({ 
        success: false,
        error: 'Invalid transaction data' 
      });
    }

    if (fromCurrency === toCurrency) {
      return res.status(400).json({ 
        success: false,
        error: 'Cannot exchange same currency' 
      });
    }

    // SQL INJECTION KORUMASI - Sadece izin verilen currency'leri kabul et
    const ALLOWED_CURRENCIES = ['PLN', 'USD', 'EUR', 'GBP'];
    if (!ALLOWED_CURRENCIES.includes(fromCurrency) || !ALLOWED_CURRENCIES.includes(toCurrency)) {
      return res.status(400).json({ 
        success: false,
        error: 'Invalid currency' 
      });
    }

    await connection.beginTransaction();

    // BACKEND'DEN GÜNCEL KURU ÇEK (NBP API)
    console.log(' Fetching current rates from NBP API...');
    const rates = await getExchangeRates();
    console.log(' Current rates:', rates);

    const fromRate = rates[fromCurrency];
    const toRate = rates[toCurrency];

    if (!fromRate || !toRate) {
      await connection.rollback();
      return res.status(400).json({ 
        success: false,
        error: 'Invalid currency' 
      });
    }

    // BACKEND'DE HESAPLA (Frontend'in gönderdiği değer kullanılmıyor!)
    const inPLN = amount * fromRate;
    const toAmount = inPLN / toRate;
    const actualRate = toRate / fromRate;

    console.log(` Exchange calculation:
      - From: ${amount} ${fromCurrency} (rate: ${fromRate})
      - In PLN: ${inPLN}
      - To: ${toAmount} ${toCurrency} (rate: ${toRate})
      - Actual rate: ${actualRate}
    `);

    // KULLANICININ BAKİYESİNİ KONTROL ET (DOĞRU ŞEMA)
    const [currentWallet] = await connection.query(
      'SELECT PLN, USD, EUR, GBP FROM Wallets WHERE userId = ?',
      [userId]
    );

    if (!currentWallet || currentWallet.length === 0) {
      await connection.rollback();
      return res.status(400).json({ 
        success: false,
        error: 'Wallet not found' 
      });
    }

    const wallet = currentWallet[0];
    const currentBalance = parseFloat(wallet[fromCurrency] || 0);
    
    if (currentBalance < amount) {
      await connection.rollback();
      return res.status(400).json({ 
        success: false,
        error: `Insufficient balance. Available: ${currentBalance.toFixed(2)} ${fromCurrency}` 
      });
    }

    // KAYNAK WALLET'TAN DÜŞ (DOĞRU ŞEMA)
    await connection.query(
      `UPDATE Wallets SET ${fromCurrency} = ${fromCurrency} - ? WHERE userId = ?`,
      [amount, userId]
    );

    // HEDEF WALLET'A EKLE (DOĞRU ŞEMA)
    await connection.query(
      `UPDATE Wallets SET ${toCurrency} = ${toCurrency} + ? WHERE userId = ?`,
      [toAmount, userId]
    );

    // TRANSACTION KAYDET
    const [txResult] = await connection.query(
      `INSERT INTO Transactions 
       (userId, type, fromCurrency, toCurrency, fromAmount, toAmount, rate) 
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [userId, 'EXCHANGE', fromCurrency, toCurrency, amount, toAmount, actualRate]
    );

    await connection.commit();

    console.log(' Exchange successful:', {
      transactionId: txResult.insertId,
      from: `${amount} ${fromCurrency}`,
      to: `${toAmount} ${toCurrency}`,
      rate: actualRate
    });

    // GÜNCEL WALLET'LARI DÖNDÜR (DOĞRU ŞEMA)
    const [updatedWallets] = await connection.query(
      'SELECT PLN, USD, EUR, GBP FROM Wallets WHERE userId = ?',
      [userId]
    );

    const wallets = updatedWallets[0];

    res.json({
      success: true,
      message: 'Exchange successful',
      transaction: {
        id: txResult.insertId,
        from: `${amount} ${fromCurrency}`,
        to: `${toAmount.toFixed(2)} ${toCurrency}`,
        rate: actualRate.toFixed(6)
      },
      wallets: {
        PLN: parseFloat(wallets.PLN),
        USD: parseFloat(wallets.USD),
        EUR: parseFloat(wallets.EUR),
        GBP: parseFloat(wallets.GBP)
      }
    });

  } catch (error) {
    await connection.rollback();
    console.error(' Exchange error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Transaction failed: ' + error.message 
    });
  } finally {
    connection.release();
  }
});

// 7. Transaction History
app.get('/api/history', authenticateToken, async (req, res) => {
    const userId = req.user.id;
    const connection = await db.getConnection();
    try {
        const [transactions] = await connection.execute(
            'SELECT id, type, fromCurrency, toCurrency, fromAmount, toAmount, rate, date FROM Transactions WHERE userId = ? ORDER BY date DESC',
            [userId]
        );

        res.json({
            message: 'Transaction history retrieved',
            history: transactions
        });
    } catch (err) {
        console.error('History Error:', err);
        res.status(500).json({ error: 'Failed to retrieve history' });
    } finally {
        if (connection) connection.release();
    }
});

// 8. Get Historical Rates
app.get('/api/rates/historical', async (req, res) => {
  try {
    const days = parseInt(req.query.days) || 30;
    if (days < 1 || days > 90) {
      return res.status(400).json({ error: 'Days must be between 1 and 90' });
    }

    const historicalRates = await getHistoricalRates(days);
    res.json({
      currency: 'PLN',
      period: `${days} days`,
      data: historicalRates
    });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Start Server
app.listen(PORT, () => {
  console.log(`API running on http://localhost:${PORT}`);
  console.log(`MySQL Persistent Database Active!`);
});