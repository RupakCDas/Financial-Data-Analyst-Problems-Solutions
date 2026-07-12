-- ================================================================
--  PROBLEM 1: Transaction Fraud Detection
--  Real-world context: Banks & FinTechs (Wells Fargo, Stripe, PayPal)
--  lose billions annually to fraudulent transactions.
--  Task: Identify suspicious patterns from raw transaction data.
-- ================================================================

CREATE DATABASE transaction_data ;


-- ── Setup: Sample transactions table ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transactions (
    txn_id          SERIAL PRIMARY KEY, -- Transaction ID
    account_id      VARCHAR(100),       -- Account ID
    merchant        VARCHAR(100),		    -- Marchant
    merchant_country VARCHAR(100),		  -- Marchant Country
    amount          NUMERIC(12,2),		  -- Transaction Amount
    txn_type        VARCHAR(100),   	  -- Transaction type ('purchase','withdrawal','transfer')
    txn_at          DATETIME(100)		    -- Transaction Time
);

SELECT * FROM transactions;


-- ── FRAUD RULE 1: Velocity check — 5+ transactions within 10 minutes ────────
-- Real-world use: Card testing attacks; bots run small transactions quickly

WITH velocity AS (
    SELECT
        account_id,
        txn_at,
       COUNT(*) OVER (
		PARTITION BY account_id
		ORDER BY UNIX_TIMESTAMP(txn_at)
		RANGE BETWEEN 600 PRECEDING AND CURRENT ROW
		) AS txns_in_10min
			FROM transactions
)
SELECT DISTINCT account_id, txn_at, MAX(txns_in_10min) AS max_txns
FROM velocity
WHERE txns_in_10min > 5
GROUP BY account_id , txn_at
ORDER BY max_txns DESC , txn_at DESC;



-- ── FRAUD RULE 2: Geographic anomaly — transaction outside home country ───────
-- Real-world: Account always transacts in US, suddenly appears in Romania

with mode_country as (
		SELECT account_id, 
        merchant_country, 
        COUNT(merchant_country) AS txn_per_cntry,
		RANK() OVER ( PARTITION BY account_id ORDER BY COUNT(merchant_country) DESC) AS rn
		FROM transactions
		GROUP BY account_id,  merchant_country
		ORDER BY account_id asc ),
home_country AS (
    SELECT
        account_id,
		merchant_country AS home_cntry,
        txn_per_cntry
    FROM mode_country
    WHERE rn = 1 AND  txn_per_cntry >= 2  -- (found a baseline transaction count from history)
    ),
anomalies AS (
    SELECT
        t.account_id,
        t.txn_id,
        t.merchant,
        t.merchant_country,
        t.amount,
        t.txn_at,
        hc.home_cntry
    FROM transactions t
    INNER JOIN home_country hc ON t.account_id = hc.account_id
    WHERE t.merchant_country <> hc.home_cntry
)
SELECT * FROM anomalies ORDER BY amount DESC LIMIT 50;


