WITH customer_last_purchase AS (
	SELECT
		customerkey,
		fullname,
		orderdate,
		ROW_NUMBER() OVER (
			PARTITION BY customerkey
		ORDER BY
			orderdate DESC
		) AS rn,
		first_purchase_date,
		cohort_year
	FROM
		cohort_analysis_optimized
) , retention AS (
	SELECT
	customerkey,
		fullname,
		orderdate AS last_purchase_date,
		CASE
		WHEN orderdate < (
			SELECT
				max(orderdate)
			FROM
				sales
		)::date - INTERVAL '6 months' THEN 'Churned'
		ELSE 'Active'
	END AS status,
	cohort_year
FROM
	customer_last_purchase
WHERE
	rn = 1
	AND first_purchase_date < (
		SELECT
			max(orderdate)
		FROM
			sales
	)::date - INTERVAL '6 months'
)

SELECT cohort_year,
status,
count(status) AS num_customers,
sum(count(status)) OVER () AS total_customers,
round(count(status) / sum(count(status)) OVER (),2) AS status_percentage
FROM retention
GROUP BY cohort_year, status
