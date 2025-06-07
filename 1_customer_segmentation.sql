--EXPLAIN ANALYZE 
WITH customer_ltv AS (
	SELECT
		customerkey,
		fullname,
		sum(total_net_revenue) AS total_ltv
	FROM
		cohort_analysis
	GROUP BY
		customerkey,
		fullname
),
customer_segments AS (
	SELECT
		percentile_cont(0.25) WITHIN GROUP (
		ORDER BY
			total_ltv
		) AS ltv_25th_percentile,
		percentile_cont(0.75) WITHIN GROUP (
		ORDER BY
			total_ltv
		) AS ltv_75th_percentile
	FROM
		customer_ltv
), segment_values AS (
SELECT
	c.*,
	CASE
		WHEN c.total_ltv < cs.ltv_25th_percentile THEN '1 - LOW VALUE'
		WHEN c.total_ltv <= cs.ltv_75th_percentile THEN '2 - MID VALUE'
		ELSE '3 - HIGH VALUE'
	END AS customer_segment
	FROM
		customer_ltv c,customer_segments cs
)

SELECT customer_segment,
sum(total_ltv) AS total_ltv,
count(customerkey),
sum(total_ltv) / count(customerkey) AS avg_ltv
FROM segment_values 
GROUP BY customer_segment 