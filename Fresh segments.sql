/*Data Exploration and Cleansing*/
--Q.1-->Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month?
SET
  SEARCH_PATH = fresh_segments;
ALTER TABLE
  interest_metrics
ALTER COLUMN
  month_year TYPE DATE USING TO_DATE(month_year, 'MM-YYYY');
--Q.2-->What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first
SET
  SEARCH_PATH = fresh_segments;
SELECT
  DATE_TRUNC('month', month_year) AS date,
  COUNT(*) AS number_of_records
FROM
  interest_metrics
GROUP BY
  month_year
ORDER BY
  month_year NULLS FIRST
--Q.3-->What do you think we should do with these null values in the fresh_segments.interest_metrics?
If month_year and interest_id columns are nulls, then we can just drop these values, or exclude them because we can not join them to other tables and can not understand what the other values, like composition, index, ranking in the rows are about.
For example, we see the composition or index but do not know which interest_id it belongs to.
--Q.4-->How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?
--We will compare the interests in the two tables using the NOT IN statement.
SET
  SEARCH_PATH = fresh_segments;
SELECT
  COUNT(distinct interest_id) AS interest_id
FROM
  interest_metrics
WHERE
  interest_id :: int NOT IN (
    SELECT
      id
    FROM
      interest_map
  )
  --0 interest_id from the interest_metrics table are not in the interest_map table
  SET
  SEARCH_PATH = fresh_segments;
SELECT
  COUNT(id) AS interest_id
FROM
  interest_map
WHERE
  id NOT IN (
    SELECT
      distinct interest_id :: int
    FROM
      interest_metrics
    WHERE
      interest_id IS NOT NULL
  )
  
--Q.5-->Summarise the id values in the fresh_segments.interest_map by its total record count in this table
SET
  SEARCH_PATH = fresh_segments;
SELECT
  COUNT(distinct id) AS total_count
FROM
  interest_map AS m
--Q.6-->What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column
SET
  SEARCH_PATH = fresh_segments;
SELECT
  distinct interest_id :: int,
  interest_name,
  interest_summary,
  created_at,
  last_modified,
  _month,
  _year,
  month_year,
  composition,
  index_value,
  ranking,
  percentile_ranking
FROM
  interest_map AS m
  LEFT JOIN interest_metrics AS im ON m.id = im.interest_id :: int
WHERE
  interest_id = '21246'
GROUP BY
  interest_name,
  id,
  interest_summary,
  created_at,
  last_modified,
  _month,
  _year,
  month_year,
  interest_id,
  composition,
  index_value,
  ranking,
  percentile_ranking
ORDER BY
  _month NULLS FIRST;
  
--Q.7-->Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?
SET
  SEARCH_PATH = fresh_segments;
WITH joined_table AS (
    SELECT
      distinct interest_id :: int,
      interest_name,
      interest_summary,
      created_at,
      last_modified,
      _month,
      _year,
      month_year,
      composition,
      index_value,
      ranking,
      percentile_ranking
    FROM
      interest_map AS m
      LEFT JOIN interest_metrics AS im ON m.id = im.interest_id :: int
    GROUP BY
      interest_name,
      id,
      interest_summary,
      created_at,
      last_modified,
      _month,
      _year,
      month_year,
      interest_id,
      composition,
      index_value,
      ranking,
      percentile_ranking
  )
SELECT
  COUNT(*)
FROM
  joined_table
WHERE
  created_at > month_year
ORDER BY
  1
 /*Interest Analysis */
--Q.1-->Which interests have been present in all month_year dates in our dataset?
--To get count of months
  SEARCH_PATH = fresh_segments;
SELECT
  COUNT(distinct month_year)
FROM
  interest_metrics
  
--to count how many times each month appeared on table
SET
  SEARCH_PATH = fresh_segments;
SELECT
  interest_name,
  COUNT(interest_id)
FROM
  interest_map AS m
  left join interest_metrics AS im ON m.id = im.interest_id :: int
GROUP BY
  1
ORDER BY
  2 DESC
  
---Final Version
SET
  SEARCH_PATH = fresh_segments;
WITH interests AS (
    SELECT
      id,
      interest_name
    FROM
      interest_map AS m
      LEFT JOIN interest_metrics AS im ON m.id = im.interest_id :: int
    GROUP BY
      1,
      2
    HAVING
      COUNT(interest_id) = 14
  )
SELECT
  interest_name
FROM
  interests
ORDER BY
  1

--Q.2-->Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?
SET
  SEARCH_PATH = fresh_segments;
WITH counted_months AS (
    SELECT
      interest_id,
      COUNT(interest_id) total_months,
      ROW_NUMBER() OVER(
        PARTITION BY COUNT(interest_id)
        ORDER BY
          COUNT(interest_id)
      ) AS rank
    FROM
      interest_metrics AS im
    GROUP BY
      1
    HAVING
      COUNT(interest_id) > 0
  )
SELECT
  total_months,
  MAX(rank) AS number_of_interests,
  CAST(
    100 * SUM(MAX(rank)) OVER (
      ORDER BY
        total_months
    ) / SUM(MAX(rank)) OVER () AS numeric(10, 2)
  ) cum_top,
  CAST(
    100 - 100 * SUM(MAX(rank)) OVER (
      ORDER BY
        total_months
    ) / SUM(MAX(rank)) OVER () AS numeric(10, 2)
  ) cum_top_reversed
FROM
  counted_months
GROUP BY
  total_months
ORDER BY
  1
--Q.3-->If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
--to get number of interests
SET
  SEARCH_PATH = fresh_segments;
WITH interests AS (
    SELECT
      id,
      interest_name
    FROM
      interest_map AS m
      LEFT JOIN interest_metrics AS im ON m.id = im.interest_id :: int
    GROUP BY
      1,
      2
    HAVING
      COUNT(interest_id) < 6
  )
SELECT
  COUNT(interest_name) AS number_of_interests
FROM
  interests
ORDER BY
  1
 --number of data points to remove
SET
  SEARCH_PATH = fresh_segments;
WITH interests AS (
    SELECT
      interest_id
    FROM
      interest_metrics AS im
    GROUP BY
      1
    HAVING
      COUNT(interest_id) < 6
  )
SELECT
  COUNT(interest_id) AS number_of_interests
FROM
  interests
ORDER BY
  1
--Q.4-->Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.
SET
  SEARCH_PATH = fresh_segments;
SELECT
  im.month_year,
  COUNT(interest_id) AS number_of_excluded_interests,
  number_of_included_interests,
  ROUND(
    100 *(
      COUNT(interest_id) / number_of_included_interests :: numeric
    ),
    1
  ) AS percent_of_excluded
FROM
  interest_metrics AS im
  JOIN (
    SELECT
      month_year,
      COUNT(interest_id) AS number_of_included_interests
    FROM
      interest_metrics AS im
    WHERE
      month_year IS NOT NULL
      AND interest_id :: int IN (
        SELECT
          interest_id :: int
        FROM
          interest_metrics
        GROUP BY
          1
        HAVING
          COUNT(interest_id) > 5
      )
    GROUP BY
      1
  ) i ON im.month_year = i.month_year
WHERE
  im.month_year IS NOT NULL
  AND interest_id :: int IN (
    SELECT
      interest_id :: int
    FROM
      interest_metrics
    GROUP BY
      1
    having
      COUNT(interest_id) < 6
  )
GROUP BY
  1,
  3
ORDER BY
  1
--Q.5-->After removing these interests - how many unique interests are there for each month?
SET
  SEARCH_PATH = fresh_segments;
SELECT
  month_year,
  COUNT(interest_id) AS number_of_interests
FROM
  interest_metrics AS im
WHERE
  month_year IS NOT NULL
  AND interest_id :: int IN (
    SELECT
      interest_id :: int
    FROM
      interest_metrics
    GROUP BY
      1
    HAVING
      COUNT(interest_id) > 5
  )
GROUP BY
  1
ORDER BY
  1

/*Segment Analysis*/

--Q.1-->Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year
SET
  SEARCH_PATH = fresh_segments;
SELECT
  interests.month_year,
  interests.interest_name,
  interests.composition,
  i_max_new.composition AS max_composition,
  i_max_new.month_year AS max_composition_month
FROM
  (
    (
      WITH max_interests AS (
        SELECT
          month_year,
          interest_name,
          composition,
          RANK() OVER (
            PARTITION BY interest_name
            ORDER BY
              composition DESC
          ) AS max_rank
        FROM
          interest_metrics AS im
          JOIN interest_map AS m ON m.id = im.interest_id :: int
        WHERE
          month_year IS NOT NULL
          AND interest_id :: int in (
            SELECT
              interest_id :: int
            FROM
              interest_metrics
            GROUP BY
              1
            HAVING
              COUNT(interest_id) > 5
          )
        GROUP BY
          1,
          2,
          3
      )
      SELECT
        month_year,
        interest_name,
        composition
      FROM
        max_interests
      WHERE
        max_rank = 1
      GROUP BY
        1,
        2,
        3
      ORDER BY
        3 DESC
      LIMIT
        10
    )
    UNION
      (
        WITH min_interests AS (
          SELECT
            month_year,
            interest_name,
            composition,
            RANK() OVER (
              PARTITION BY interest_name
              ORDER BY
                composition
            ) AS min_rank
          FROM
            interest_metrics AS im
            JOIN interest_map AS m ON m.id = im.interest_id :: int
          WHERE
            month_year IS NOT NULL
            AND interest_id :: int in (
              SELECT
                interest_id :: int
              FROM
                interest_metrics
              GROUP BY
                1
              HAVING
                COUNT(interest_id) > 5
            )
          GROUP BY
            1,
            2,
            3
        )
        SELECT
          month_year,
          interest_name,
          composition
        FROM
          min_interests
        WHERE
          min_rank = 1
        GROUP BY
          1,
          2,
          3
        ORDER BY
          3
        LIMIT
          10
      )
  ) AS interests
  JOIN (
    WITH max_interests AS (
      SELECT
        month_year,
        interest_name,
        composition,
        RANK() OVER (
          PARTITION BY interest_name
          ORDER BY
            composition DESC
        ) AS max_rank
      FROM
        interest_metrics AS im
        JOIN interest_map AS m ON m.id = im.interest_id :: int
      WHERE
        month_year IS NOT NULL
        AND interest_id :: int in (
          SELECT
            interest_id :: int
          FROM
            interest_metrics
          GROUP BY
            1
          HAVING
            COUNT(interest_id) > 5
        )
      GROUP BY
        1,
        2,
        3
    )
    SELECT
      month_year,
      interest_name,
      composition
    FROM
      max_interests
    WHERE
      max_rank = 1
    GROUP BY
      1,
      2,
      3
    ORDER BY
      3 DESC
  ) i_max_new on interests.interest_name = i_max_new.interest_name
ORDER BY
  3 DESC
--Q.2-->Which 5 interests had the lowest average ranking value?
SET
  SEARCH_PATH = fresh_segments;
WITH ranking AS (
    SELECT
      interest_name,
      AVG(ranking) :: numeric(10, 2) AS avg_ranking,
      RANK() OVER (
        ORDER BY
          AVG(ranking) DESC
      ) AS rank
    FROM
      interest_metrics AS im
      JOIN interest_map AS m ON m.id = im.interest_id :: int
    WHERE
      month_year IS NOT NULL
      AND interest_id :: int IN (
        SELECT
          interest_id :: int
        FROM
          interest_metrics
        GROUP BY
          1
        HAVING
          COUNT(interest_id) > 5
      )
    GROUP BY
      1
  )
SELECT
  interest_name,
  avg_ranking
FROM
  ranking
WHERE
  rank between 0
  AND 5
--Q.3-->Which 5 interests had the largest standard deviation in their percentile_ranking value?
SET
  SEARCH_PATH = fresh_segments;
WITH ranking AS (
    SELECT
      id,
      interest_name,
      STDDEV(percentile_ranking) :: numeric(10, 2) AS standard_deviation,
      RANK() OVER (
        ORDER BY
          STDDEV(percentile_ranking) DESC
      ) AS rank
    FROM
      interest_metrics AS im
      JOIN interest_map AS m ON m.id = im.interest_id :: int
    WHERE
      month_year IS NOT NULL
      AND interest_id :: int IN (
        SELECT
          interest_id :: int
        FROM
          interest_metrics
        GROUP BY
          1
        having
          count(interest_id) > 5
      )
    GROUP BY
      1,
      2
  )
SELECT
  interest_name,
  standard_deviation
FROM
  ranking
WHERE
  rank between 0
  AND 5
--Q.4-->For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?
SET
  SEARCH_PATH = fresh_segments;
WITH ranking AS (
    SELECT
      month_year,
      id,
      interest_name,
      percentile_ranking,
      RANK() OVER (
        PARTITION BY id
        ORDER BY
          percentile_ranking
      ) AS min_rank,
      RANK() OVER (
        PARTITION BY id
        ORDER BY
          percentile_ranking DESC
      ) AS max_rank
    FROM
      interest_metrics AS im
      JOIN interest_map AS m ON m.id = im.interest_id :: int
    WHERE
      month_year IS NOT NULL
      AND interest_id :: int IN (
        SELECT
          interest_id :: int
        FROM
          interest_metrics
        GROUP BY
          1
        HAVING
          COUNT(interest_id) > 5
      )
      AND id IN (
        WITH ranking AS (
          SELECT
            id,
            interest_name,
            STDDEV(percentile_ranking) :: numeric(10, 2) AS standard_deviation,
            RANK() OVER (
              ORDER BY
                STDDEV(percentile_ranking) DESC
            ) AS rank
          FROM
            interest_metrics AS im
            JOIN interest_map AS m ON m.id = im.interest_id :: int
          WHERE
            month_year IS NOT NULL
            AND interest_id :: int IN (
              SELECT
                interest_id :: int
              FROM
                interest_metrics
              GROUP BY
                1
              having
                count(interest_id) > 5
            )
          GROUP BY
            1,
            2
        )
        SELECT
          id
        FROM
          ranking
        WHERE
          rank between 0
          AND 5
      )
    GROUP BY
      1,
      2,
      3,
      4
  )
SELECT
  month_year,
  interest_name,
  percentile_ranking
FROM
  ranking
WHERE
  min_rank = 1
  or max_rank = 1
GROUP BY
  1,
  2,
  3
ORDER BY
  2,
  3 DESC
  
--Q.5-->How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?
The customers in this segment love to travel, some of them are probably business travellers, they prefer luxury lifestyle and go into sports
. We should show the products or services related to luxury travel or luxury lifestyle (furniture, cosmetics, apparel), and avoid budget segment or any product or services related to random interests like 
computer games or astrology. We also can exclude some topics related to locations that are out of area of the customers interests like Tampa or Oregon, 
because the customers possibly has already visited those locations and do not wish to return there. 
Also we can exclude topics related to some long-term needs and the long-term use products, 
that the customers have probably already purchased. For example, if a customer had an interest in Luxury Furniture or Gym Equipment, they might have purchased those products and do not have interest in this topic anymore.
So in general we need to focus on the interests with high composition value but we need to track this metric to define when customers lose their interest in the topic.

/*Index Analysis */
--Q.1-->What is the top 10 interests by the average composition for each month?
SET
  SEARCH_PATH = fresh_segments;
WITH ranking AS (
    SELECT
      month_year,
      id,
      interest_name,
      avg_composition,
      RANK() OVER (
        PARTITION BY month_year
        ORDER BY
          avg_composition DESC
      ) AS max_rank
    FROM
      interest_metrics AS im
      JOIN interest_map AS m ON m.id = im.interest_id :: int,
      LATERAL(
        SELECT
          (composition / index_value) :: numeric(10, 2) AS avg_composition
      ) ac
    WHERE
      month_year IS NOT NULL
      AND interest_id :: int IN (
        SELECT
          interest_id :: int
        FROM
          interest_metrics
        GROUP BY
          1
        HAVING
          COUNT(interest_id) > 5
      )
    GROUP BY
      1,
      2,
      3,
      4
  )
SELECT
  month_year,
  interest_name,
  avg_composition
FROM
  ranking
WHERE
  max_rank between 1
  AND 10
ORDER BY
  1,
  3 DESC
--Q.2-->For all of these top 10 interests - which interest appears the most often?
SET
  SEARCH_PATH = fresh_segments;
WITH ranking AS (
    SELECT
      month_year,
      id,
      interest_name,
      avg_composition,
      RANK() OVER (
        PARTITION BY month_year
        ORDER BY
          avg_composition DESC
      ) AS max_rank
    FROM
      interest_metrics AS im
      JOIN interest_map AS m on m.id = im.interest_id :: int,
      LATERAL(
        SELECT
          (composition / index_value) :: numeric(10, 2) AS avg_composition
      ) ac
    WHERE
      month_year IS NOT NULL
      AND interest_id :: int IN (
        SELECT
          interest_id :: int
        FROM
          interest_metrics
        GROUP BY
          1
        HAVING
          COUNT(interest_id) > 5
      )
    GROUP BY
      1,
      2,
      3,
      4
  )
SELECT
  interest_name,
  COUNT(interest_name) AS months_in_top_1
FROM
  ranking
WHERE
  max_rank = 1
GROUP BY
  1
ORDER BY
  2 DESC
--Q.3-->What is the average of the average composition for the top 10 interests for each month?
SET
  SEARCH_PATH = fresh_segments;
SELECT
  month_year,
  AVG(avg_composition) :: numeric(10, 2) AS average_rating
FROM
  (
    WITH ranking AS (
      SELECT
        month_year,
        id,
        interest_name,
        avg_composition,
        RANK() OVER (
          PARTITION BY month_year
          ORDER BY
            avg_composition DESC
        ) AS max_rank
      FROM
        interest_metrics AS im
        JOIN interest_map AS m ON m.id = im.interest_id :: int,
        LATERAL(
          SELECT
            (composition / index_value) :: numeric(10, 2) AS avg_composition
        ) ac
      WHERE
        month_year IS NOT NULL
        AND interest_id :: int IN (
          SELECT
            interest_id :: int
          FROM
            interest_metrics
          GROUP BY
            1
          HAVING
            COUNT(interest_id) > 5
        )
      GROUP BY
        1,
        2,
        3,
        4
    )
    SELECT
      month_year,
      interest_name,
      avg_composition
    FROM
      ranking
    WHERE
      max_rank between 1
      AND 10
  ) r
GROUP BY
  1
ORDER BY
  1
  
--Q.4-->What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.
SET
  SEARCH_PATH = fresh_segments;
SELECT
  *
FROM
  (
    WITH ranking AS (
      SELECT
        month_year,
        id,
        interest_name,
        avg_composition,
        RANK() OVER (
          PARTITION BY month_year
          ORDER BY
            avg_composition DESC
        ) AS max_rank
      FROM
        interest_metrics AS im
        JOIN interest_map AS m ON m.id = im.interest_id :: int,
        LATERAL(
          SELECT
            (composition / index_value) :: numeric(10, 2) AS avg_composition
        ) ac
      WHERE
        month_year IS NOT NULL
        AND interest_id :: int IN (
          SELECT
            interest_id :: int
          FROM
            interest_metrics
          GROUP BY
            1
          HAVING
            COUNT(interest_id) > 5
        )
      GROUP BY
        1,
        2,
        3,
        4
    )
    SELECT
      month_year,
      interest_name,
      avg_composition AS max_index_composition,
      (
        AVG(avg_composition) OVER(
          ORDER BY
            month_year ROWS BETWEEN 2 PRECEDING
            AND CURRENT ROW
        )
      ) :: numeric(10, 2) AS _3_month_moving_avg,
      CONCAT(
        LAG(interest_name) OVER (
          ORDER BY
            month_year
        ),
        ': ',
        LAG(avg_composition) OVER (
          ORDER BY
            month_year
        )
      ) AS _1_month_ago,
      CONCAT(
        LAG(interest_name, 2) OVER (
          ORDER BY
            month_year
        ),
        ': ',
        LAG(avg_composition, 2) OVER (
          ORDER BY
            month_year
        )
      ) AS _2_month_ago
    FROM
      ranking
    WHERE
      max_rank = 1
  ) r
WHERE
  month_year > '2018-08-01'
ORDER BY
  1
--Q.5-->Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments?

I think that the users interests may have changed, and the users are less interested in some topics now if at all. Users "burnt out", and the index composition value has decreased. Maybe some users (or interests) need to be transferred to another segment. However,
some interests keep high index_composition value, it possibly means that these topics are always in the users interest area