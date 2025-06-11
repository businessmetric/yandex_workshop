-- Сайт utmmetki.ru база данных postgresql

-- Доля лояльных пользователей (какой процент пользователей посещает сайт чаще 2 раз в месяц на протяжении 3 месяцев)

WITH monthly_visits AS (
  SELECT
    client_id,
    DATE_TRUNC('month', date_time) AS month,
    COUNT(DISTINCT DATE(date_time)) AS visits_per_month
  FROM 
    public.yandex_metrika_project_140_246_hits
  WHERE 
    date_time >= CURRENT_DATE - INTERVAL '3 months'
    AND is_page_view = 1  -- Учитываем только просмотры страниц
  GROUP BY 
    client_id, 
    DATE_TRUNC('month', date_time)
),

loyal_users AS (
  SELECT
    client_id,
    COUNT(month) AS active_months,
    SUM(visits_per_month) AS total_visits
  FROM 
    monthly_visits
  WHERE 
    visits_per_month >= 2  -- 2+ посещения в месяц
  GROUP BY 
    client_id
  HAVING 
    COUNT(month) = 3  -- Активны все 3 месяца
)



SELECT
  COUNT(DISTINCT hm.client_id) AS total_unique_users,
  
  COUNT(DISTINCT CASE WHEN lu.client_id IS NOT NULL THEN lu.client_id END) AS loyal_users_count,
  
  ROUND(COUNT(DISTINCT CASE WHEN lu.client_id IS NOT NULL THEN lu.client_id END) * 100.0 / 
        NULLIF(COUNT(DISTINCT hm.client_id), 0), 2) AS loyal_users_percentage,
        
  AVG(CASE WHEN lu.client_id IS NOT NULL THEN lu.total_visits END) AS avg_visits_loyal_users,
  AVG(CASE WHEN lu.client_id IS NULL THEN mv.visits_per_month END) AS avg_visits_other_users
FROM 
  public.yandex_metrika_project_140_246_hits hm
LEFT JOIN 
  monthly_visits mv ON hm.client_id = mv.client_id
LEFT JOIN 
  loyal_users lu ON hm.client_id = lu.client_id
WHERE 
  hm.date_time >= CURRENT_DATE - INTERVAL '3 months'
