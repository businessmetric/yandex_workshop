-- сайт utmmetki.ru база postgresql
-- Какие источники генерации ссылок чаще пользователи выбирают
  SELECT
    (parsed_params::json->>'source') AS source,
    COUNT(DISTINCT watch_id) AS unique_clicks
  FROM 
    public.yandex_metrika_project_140_246_hits
  WHERE
    parsed_params::json->>'source' IS NOT NULL 
    AND date_time >= CURRENT_DATE - INTERVAL '3 months'
  GROUP BY
    parsed_params::json->>'source'
  ORDER BY 
  	unique_clicks DESC
