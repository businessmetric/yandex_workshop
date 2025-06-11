-- Сайт utmmetki.ru база данных postgresql
-- Лояльные пользователи (пользователей посещает сайт чаще 2 раз в месяц на протяжении 3 месяцев) -- загрузка в метрику через Veeneo
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

select * from loyal_users 
