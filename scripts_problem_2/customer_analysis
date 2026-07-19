-- ================================================================
--  PROBLEM 2: Customer Churn & Revenue Retention Analysis
--  Real-world context: Netflix, Adobe, SaaS companies track this daily.
--  Task: Cohort retention, MRR (Monthly Recurring Revenue) movement, churn prediction signals.
-- ================================================================
CREATE DATABASE cust_info ;
CREATE TABLE IF NOT EXISTS subscriptions (
    sub_id          VARCHAR(60) PRIMARY KEY,
    customer_id     VARCHAR(60),
    plan            VARCHAR(30),   -- 'basic','pro','enterprise'
    mrr             NUMERIC(10,2), -- monthly recurring revenue
    started_at      DATETIME,
    ended_at        DATETIME,      -- NULL = still active
    cancel_reason   VARCHAR(100)
);
SELECT * FROM subscriptions;

CREATE TABLE IF NOT EXISTS customer_events (
    event_id        VARCHAR(60) PRIMARY KEY,
    customer_id     VARCHAR(60),
    event_type      VARCHAR(60),   -- 'login','feature_used','support_ticket','downgrade'
    event_at        DATETIME
);
SELECT * FROM customer_events;

-- ── PROBLEM 2B: MRR Movement — New / Expansion / Contraction / Churn ──────────
-- Real-world: company tracks this every month to understand revenue health

WITH monthly_mrr AS (
    SELECT
        customer_id,
        DATE_SUB(started_at, INTERVAL DAY(started_at) - 1 DAY) AS activate_month,
        SUM(mrr) AS mrr
    FROM subscriptions
    WHERE ended_at IS NULL OR ended_at >= started_at
    GROUP BY customer_id, activate_month
),
mrr_with_prev AS (
    SELECT
        customer_id,
        activate_month,
        mrr,
        LAG(mrr) OVER (PARTITION BY customer_id ORDER BY activate_month) AS prev_mrr
    FROM monthly_mrr
)
SELECT
    activate_month,
    SUM(CASE WHEN prev_mrr IS NULL THEN mrr ELSE 0 END) AS new_mrr,
    SUM(CASE WHEN prev_mrr IS NOT NULL AND mrr > prev_mrr THEN mrr - prev_mrr ELSE 0 END)  AS expansion_mrr,
    SUM(CASE WHEN prev_mrr IS NOT NULL AND mrr < prev_mrr AND mrr > 0 THEN prev_mrr - mrr ELSE 0 END)                         AS contraction_mrr,
    SUM(CASE WHEN prev_mrr IS NOT NULL AND mrr = 0 THEN prev_mrr ELSE 0 END) AS churned_mrr,
    SUM(mrr) AS total_mrr
FROM mrr_with_prev
GROUP BY activate_month
ORDER BY activate_month;
