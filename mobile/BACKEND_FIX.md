# 🔧 Backend Exchange Endpoint Düzeltmesi

## Sorun
`/api/exchange` endpoint'i yanlış database şeması kullanıyor.

Mevcut Wallets tablosu yapısı:
- `userId` (INT)
- `PLN` (DECIMAL)
- `USD` (DECIMAL)
- `EUR` (DECIMAL)
- `GBP` (DECIMAL)

Ama exchange endpoint şunu kullanıyor:
- `user_id`, `currency`, `balance` (YANLIŞ!)

---

## Çözüm: server.js içindeki /api/exchange endpoint'ini değiştir

```javascript
// 6. Currency Exchange (Atomic Transaction) - FIXED VERSION
app.post('/api/exchange', authenticateToken, async (req, res) => {
  const connection = await db.getConnection();
  
  try {
    const { fromCurrency, toCurrency, amount } = req.body;
    const userId = req.user.id;

    // ✅ VALIDATION
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

    await connection.beginTransaction();

    // ✅ BACKEND'DEN GÜNCEL KURU ÇEK (NBP API)
    console.log('🔒 Fetching current rates from NBP API...');
    const rates = await getExchangeRates();
    console.log('💹 Current rates:', rates);

    const fromRate = rates[fromCurrency];
    const toRate = rates[toCurrency];

    if (!fromRate || !toRate) {
      await connection.rollback();
      return res.status(400).json({ 
        success: false,
        error: 'Invalid currency' 
      });
    }

    // ✅ BACKEND'DE HESAPLA (Frontend'in gönderdiği değer kullanılmıyor!)
    const inPLN = amount * fromRate;
    const toAmount = inPLN / toRate;
    const actualRate = toRate / fromRate;

    console.log(`🧮 Exchange calculation:
      - From: ${amount} ${fromCurrency} (rate: ${fromRate})
      - In PLN: ${inPLN}
      - To: ${toAmount} ${toCurrency} (rate: ${toRate})
      - Actual rate: ${actualRate}
    `);

    // ✅ KULLANICININ BAKİYESİNİ KONTROL ET (DOĞRU ŞEMA)
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

    // ✅ KAYNAK WALLET'TAN DÜŞ (DOĞRU ŞEMA)
    await connection.query(
      `UPDATE Wallets SET ${fromCurrency} = ${fromCurrency} - ? WHERE userId = ?`,
      [amount, userId]
    );

    // ✅ HEDEF WALLET'A EKLE (DOĞRU ŞEMA)
    await connection.query(
      `UPDATE Wallets SET ${toCurrency} = ${toCurrency} + ? WHERE userId = ?`,
      [toAmount, userId]
    );

    // ✅ TRANSACTION KAYDET
    const [txResult] = await connection.query(
      `INSERT INTO Transactions 
       (userId, type, fromCurrency, toCurrency, fromAmount, toAmount, rate) 
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [userId, 'EXCHANGE', fromCurrency, toCurrency, amount, toAmount, actualRate]
    );

    await connection.commit();

    console.log('✅ Exchange successful:', {
      transactionId: txResult.insertId,
      from: `${amount} ${fromCurrency}`,
      to: `${toAmount} ${toCurrency}`,
      rate: actualRate
    });

    // ✅ GÜNCEL WALLET'LARI DÖNDÜR (DOĞRU ŞEMA)
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
    console.error('❌ Exchange error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Transaction failed: ' + error.message 
    });
  } finally {
    connection.release();
  }
});
```

---

## Değişiklikler

### 1. Bakiye Kontrolü
**Önce (YANLIŞ):**
```javascript
const [fromWallet] = await connection.query(
  'SELECT balance FROM Wallets WHERE user_id = ? AND currency = ?',
  [userId, fromCurrency]
);
```

**Sonra (DOĞRU):**
```javascript
const [currentWallet] = await connection.query(
  'SELECT PLN, USD, EUR, GBP FROM Wallets WHERE userId = ?',
  [userId]
);
const currentBalance = parseFloat(wallet[fromCurrency] || 0);
```

### 2. Wallet Güncelleme
**Önce (YANLIŞ):**
```javascript
await connection.query(
  'UPDATE Wallets SET balance = balance - ? WHERE user_id = ? AND currency = ?',
  [amount, userId, fromCurrency]
);
```

**Sonra (DOĞRU):**
```javascript
await connection.query(
  `UPDATE Wallets SET ${fromCurrency} = ${fromCurrency} - ? WHERE userId = ?`,
  [amount, userId]
);
```

### 3. Transaction Insert
**Önce (YANLIŞ):**
```javascript
INSERT INTO Transactions 
(user_id, type, from_currency, to_currency, from_amount, to_amount, rate, status) 
VALUES (?, ?, ?, ?, ?, ?, ?, ?)
```

**Sonra (DOĞRU):**
```javascript
INSERT INTO Transactions 
(userId, type, fromCurrency, toCurrency, fromAmount, toAmount, rate) 
VALUES (?, ?, ?, ?, ?, ?, ?)
```

---

## Test Adımları

1. **Backend'i yeniden başlat**
   ```bash
   node server.js
   ```

2. **Flutter uygulamasını çalıştır**
   ```bash
   flutter run
   ```

3. **Test senaryosu**
   - Login yap
   - Add Funds: 1000 PLN ekle
   - Exchange: 100 PLN → USD çevir
   - Backend log'unda NBP API çağrısını gör
   - Başarılı mesaj al
   - Wallet'ların güncellendiğini kontrol et

4. **Exploit testi (Postman)**
   ```json
   POST http://localhost:8080/api/exchange
   Headers: Authorization: Bearer <token>
   Body: {
     "fromCurrency": "PLN",
     "toCurrency": "USD",
     "amount": 100,
     "rate": 0.001  // ❌ Bu ignore edilmeli!
   }
   ```
   
   **Beklenen:** Backend bu rate'i yok saymalı, NBP'den kendi çektiği kuru kullanmalı.

---

## Güvenlik Kontrolleri

✅ Frontend artık `rate` gönderemiyor  
✅ Backend her seferinde NBP'den güncel kuru çekiyor  
✅ Backend kendi hesaplıyor  
✅ Kullanıcı manipülasyon yapamıyor  
✅ Database şeması tutarlı  

---

## Ek Öneri: SQL Injection Koruması

Dinamik SQL kullanırken dikkatli ol:
```javascript
// ⚠️ Potansiyel SQL Injection riski
`UPDATE Wallets SET ${fromCurrency} = ${fromCurrency} - ? WHERE userId = ?`
```

**Güvenli alternatif:** Sadece izin verilen currency'leri kabul et:
```javascript
const ALLOWED_CURRENCIES = ['PLN', 'USD', 'EUR', 'GBP'];

if (!ALLOWED_CURRENCIES.includes(fromCurrency) || !ALLOWED_CURRENCIES.includes(toCurrency)) {
  return res.status(400).json({ 
    success: false,
    error: 'Invalid currency' 
  });
}
```

Bu kontrol zaten `getExchangeRates()` içinde dolaylı olarak var (sadece bu 4 currency için rate dönüyor), ama explicit kontrol daha güvenli.
