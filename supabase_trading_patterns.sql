-- =============================================================================
-- SACCO Trading Patterns & Analytics — Run this in Supabase SQL Editor
-- =============================================================================
-- These functions provide real trading pattern data for the Flutter frontend.
-- They query across tenant schemas using the public.saccos registry.
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. SACCO Trading Pattern Summary (per SACCO)
-- ─────────────────────────────────────────────────────────────────────────────
-- Returns: volume trend, price movement, member activity, volatility score
CREATE OR REPLACE FUNCTION public.get_sacco_trading_patterns()
RETURNS TABLE (
    sacco_id UUID,
    sacco_name VARCHAR,
    schema_name VARCHAR,
    total_volume NUMERIC,
    transaction_count BIGINT,
    avg_transaction_amount NUMERIC,
    member_count BIGINT,
    product_count BIGINT,
    contribution_ratio NUMERIC,
    withdrawal_ratio NUMERIC,
    loan_ratio NUMERIC,
    volatility_index NUMERIC,
    trend_direction VARCHAR,
    last_30d_volume NUMERIC,
    prev_30d_volume NUMERIC,
    volume_change_pct NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    sacco_rec RECORD;
    sql_text TEXT;
BEGIN
    FOR sacco_rec IN
        SELECT s.sacco_id, s.sacco_name, s.schema_name
        FROM public.saccos s
        ORDER BY s.sacco_name
    LOOP
        -- Total volume across all products
        sql_text := format(
            'SELECT
                COALESCE(SUM(t.amount), 0),
                COUNT(t.transaction_id),
                COALESCE(AVG(t.amount), 0),
                COUNT(DISTINCT t.user_id),
                COUNT(DISTINCT p.product_id)
            FROM %I.transactions t
            LEFT JOIN %I.products p ON t.product_id = p.product_id',
            sacco_rec.schema_name, sacco_rec.schema_name
        );
        EXECUTE sql_text INTO total_volume, transaction_count, avg_transaction_amount, member_count, product_count;

        -- Transaction type ratios
        sql_text := format(
            'SELECT
                COALESCE(SUM(CASE WHEN transaction_type = ''Contribution'' THEN amount ELSE 0 END), 0),
                COALESCE(SUM(CASE WHEN transaction_type = ''Withdrawal'' THEN amount ELSE 0 END), 0),
                COALESCE(SUM(CASE WHEN transaction_type = ''Loan_Repayment'' THEN amount ELSE 0 END), 0)
            FROM %I.transactions',
            sacco_rec.schema_name
        );
        EXECUTE sql_text INTO contribution_ratio, withdrawal_ratio, loan_ratio;

        -- Volume trend (last 30 days vs previous 30 days)
        sql_text := format(
            'SELECT
                COALESCE(SUM(CASE WHEN created_at >= NOW() - INTERVAL ''30 days'' THEN amount ELSE 0 END), 0),
                COALESCE(SUM(CASE WHEN created_at >= NOW() - INTERVAL ''60 days'' AND created_at < NOW() - INTERVAL ''30 days'' THEN amount ELSE 0 END), 0)
            FROM %I.transactions',
            sacco_rec.schema_name
        );
        EXECUTE sql_text INTO last_30d_volume, prev_30d_volume;

        -- Volatility index (std dev of daily totals / mean daily total)
        sql_text := format(
            'SELECT
                CASE WHEN AVG(daily_totals) > 0
                    THEN COALESCE(STDDEV(daily_totals) / AVG(daily_totals), 0)
                    ELSE 0
                END
            FROM (
                SELECT DATE(created_at) as tx_date, SUM(amount) as daily_totals
                FROM %I.transactions
                WHERE created_at >= NOW() - INTERVAL ''90 days''
                GROUP BY DATE(created_at)
           ) daily',
            sacco_rec.schema_name
        );
        EXECUTE sql_text INTO volatility_index;

        sacco_id := sacco_rec.sacco_id;
        sacco_name := sacco_rec.sacco_name;
        schema_name := sacco_rec.schema_name;

        -- Normalize ratios to percentages
        IF total_volume > 0 THEN
            contribution_ratio := (contribution_ratio / total_volume) * 100;
            withdrawal_ratio := (withdrawal_ratio / total_volume) * 100;
            loan_ratio := (loan_ratio / total_volume) * 100;
        END IF;

        -- Volume change percentage
        IF prev_30d_volume > 0 THEN
            volume_change_pct := ((last_30d_volume - prev_30d_volume) / prev_30d_volume) * 100;
        ELSE
            volume_change_pct := 0;
        END IF;

        -- Trend direction
        IF volume_change_pct > 5 THEN
            trend_direction := 'BULLISH';
        ELSIF volume_change_pct < -5 THEN
            trend_direction := 'BEARISH';
        ELSE
            trend_direction := 'STABLE';
        END IF;

        RETURN NEXT;
    END LOOP;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. SACCO Daily Trading Volume History (for charts)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_sacco_daily_volume(
    target_schema_name TEXT,
    days_back INT DEFAULT 30
)
RETURNS TABLE (
    tx_date DATE,
    total_amount NUMERIC,
    tx_count BIGINT,
    contributions NUMERIC,
    withdrawals NUMERIC,
    loan_repayments NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY EXECUTE format(
        'SELECT
            DATE(created_at) as tx_date,
            SUM(amount) as total_amount,
            COUNT(transaction_id) as tx_count,
            SUM(CASE WHEN transaction_type = ''Contribution'' THEN amount ELSE 0 END) as contributions,
            SUM(CASE WHEN transaction_type = ''Withdrawal'' THEN amount ELSE 0 END) as withdrawals,
            SUM(CASE WHEN transaction_type = ''Loan_Repayment'' THEN amount ELSE 0 END) as loan_repayments
        FROM %I.transactions
        WHERE created_at >= NOW() - ($1 || '' days'')::INTERVAL
        GROUP BY DATE(created_at)
        ORDER BY tx_date ASC',
        target_schema_name
    ) USING days_back;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Platform-Wide Market Overview
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_platform_market_overview()
RETURNS TABLE (
    total_saccos BIGINT,
    total_members BIGINT,
    total_volume NUMERIC,
    total_transactions BIGINT,
    active_saccos BIGINT,
    avg_sacco_volume NUMERIC,
    top_performing_sacco VARCHAR,
    top_performing_volume NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    sacco_rec RECORD;
    running_members BIGINT := 0;
    running_volume NUMERIC := 0;
    running_txns BIGINT := 0;
    active_count BIGINT := 0;
    top_sacco VARCHAR := '';
    top_vol NUMERIC := 0;
    sacco_vol NUMERIC;
    sacco_members BIGINT;
    sacco_txns BIGINT;
    sacco_name VARCHAR;
BEGIN
    FOR sacco_rec IN SELECT s.sacco_name, s.schema_name FROM public.saccos s LOOP
        EXECUTE format(
            'SELECT
                COALESCE(COUNT(DISTINCT user_id), 0),
                COALESCE(SUM(amount), 0),
                COUNT(transaction_id)
            FROM %I.transactions WHERE created_at >= NOW() - INTERVAL ''90 days''',
            sacco_rec.schema_name
        ) INTO sacco_members, sacco_vol, sacco_txns;

        running_members := running_members + sacco_members;
        running_volume := running_volume + sacco_vol;
        running_txns := running_txns + sacco_txns;

        IF sacco_vol > 0 THEN active_count := active_count + 1; END IF;

        IF sacco_vol > top_vol THEN
            top_vol := sacco_vol;
            top_sacco := sacco_rec.sacco_name;
        END IF;
    END LOOP;

    total_saccos := (SELECT COUNT(*) FROM public.saccos);
    total_members := running_members;
    total_volume := running_volume;
    total_transactions := running_txns;
    active_saccos := active_count;
    avg_sacco_volume := CASE WHEN total_saccos > 0 THEN running_volume / total_saccos ELSE 0 END;
    top_performing_sacco := top_sacco;
    top_performing_volume := top_vol;

    RETURN NEXT;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Member Activity Patterns (per SACCO)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_member_activity_patterns(
    target_schema_name TEXT
)
RETURNS TABLE (
    period_label VARCHAR,
    active_members BIGINT,
    new_members BIGINT,
    total_volume NUMERIC,
    avg_per_member NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY EXECUTE format(
        'SELECT
            CASE
                WHEN DATE_TRUNC(''month'', created_at) = DATE_TRUNC(''month'', NOW()) THEN ''This Month''
                WHEN DATE_TRUNC(''month'', created_at) = DATE_TRUNC(''month'', NOW() - INTERVAL ''1 month'') THEN ''Last Month''
                ELSE TO_CHAR(DATE_TRUNC(''month'', created_at), ''Mon YYYY'')
            END,
            COUNT(DISTINCT user_id),
            COUNT(DISTINCT CASE WHEN created_at >= NOW() - INTERVAL ''30 days'' THEN user_id END),
            SUM(amount),
            CASE WHEN COUNT(DISTINCT user_id) > 0 THEN SUM(amount) / COUNT(DISTINCT user_id) ELSE 0 END
        FROM %I.transactions
        WHERE created_at >= NOW() - INTERVAL ''6 months''
        GROUP BY DATE_TRUNC(''month'', created_at)
        ORDER BY DATE_TRUNC(''month'', created_at) DESC
        LIMIT 6',
        target_schema_name
    );
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Product Performance Breakdown (per SACCO)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_product_performance(
    target_schema_name TEXT
)
RETURNS TABLE (
    product_name VARCHAR,
    total_invested NUMERIC,
    member_count BIGINT,
    transaction_count BIGINT,
    avg_investment NUMERIC,
    interest_rate NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY EXECUTE format(
        'SELECT
            p.product_name,
            COALESCE(SUM(t.amount), 0) as total_invested,
            COUNT(DISTINCT t.user_id) as member_count,
            COUNT(t.transaction_id) as transaction_count,
            CASE WHEN COUNT(DISTINCT t.user_id) > 0
                THEN COALESCE(SUM(t.amount), 0) / COUNT(DISTINCT t.user_id)
                ELSE 0 END as avg_investment,
            p.interest_rate
        FROM %I.products p
        LEFT JOIN %I.transactions t ON p.product_id = t.product_id
        GROUP BY p.product_id, p.product_name, p.interest_rate
        ORDER BY total_invested DESC',
        target_schema_name, target_schema_name
    );
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. SACCO Leaderboard (ranked by total volume)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_sacco_leaderboard()
RETURNS TABLE (
    rank BIGINT,
    sacco_name VARCHAR,
    total_volume NUMERIC,
    member_count BIGINT,
    transaction_count BIGINT,
    trend_direction VARCHAR
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    sacco_rec RECORD;
    r BIGINT := 0;
BEGIN
    FOR sacco_rec IN
        SELECT s.sacco_name, s.schema_name
        FROM public.saccos s
        ORDER BY s.sacco_name
    LOOP
        EXECUTE format(
            'SELECT
                COALESCE(SUM(amount), 0),
                COUNT(DISTINCT user_id),
                COUNT(transaction_id)
            FROM %I.transactions',
            sacco_rec.schema_name
        ) INTO total_volume, member_count, transaction_count;

        IF total_volume > 0 THEN
            r := r + 1;
            rank := r;
            sacco_name := sacco_rec.sacco_name;
            trend_direction := CASE
                WHEN total_volume > 100000000 THEN 'HIGH'
                WHEN total_volume > 50000000 THEN 'MEDIUM'
                ELSE 'LOW'
            END;
            RETURN NEXT;
        END IF;
    END LOOP;
END;
$$;
