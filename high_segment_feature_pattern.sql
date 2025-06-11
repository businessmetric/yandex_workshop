-- сайт utmmetki.ru база postgresql

-- Какой паттерн по использованию фичей присущ самым лояльным группам

WITH user_activity AS (
  SELECT
    client_id,
    SUM(CASE WHEN goals_id IS NOT NULL THEN 1 ELSE 0 END) AS total_goal_actions,
    COUNT(*) AS total_events,
    SUM(CASE WHEN 290733680 = ANY(goals_id) THEN 1 ELSE 0 END) AS choose_utm_source_count,
    SUM(CASE WHEN 290733959 = ANY(goals_id) THEN 1 ELSE 0 END) AS short_utm_result_count,
    SUM(CASE WHEN 351807360 = ANY(goals_id) THEN 1 ELSE 0 END) AS add_parameter_click_count,
    SUM(CASE WHEN 351807364 = ANY(goals_id) THEN 1 ELSE 0 END) AS delete_parameter_click_count,
    SUM(CASE WHEN 349404879 = ANY(goals_id) THEN 1 ELSE 0 END) AS final_modal_open_count,
    SUM(CASE WHEN 349404905 = ANY(goals_id) THEN 1 ELSE 0 END) AS modal_edit_count,
    SUM(CASE WHEN 349404944 = ANY(goals_id) THEN 1 ELSE 0 END) AS modal_copy_count
  FROM 
    public.yandex_metrika_project_140_246_hits
  WHERE 
  	date_time >= CURRENT_DATE - INTERVAL '6 months'
  GROUP BY
    client_id
  
),

user_segments AS (
  SELECT
    client_id,
    total_goal_actions,
    total_events,
    -- Определяем сегменты пользователей по квартилям активности
    CASE
      WHEN total_goal_actions >= (SELECT percentile_cont(0.75) WITHIN GROUP (ORDER BY total_goal_actions) FROM user_activity) THEN 'high'
      WHEN total_goal_actions >= (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY total_goal_actions) FROM user_activity) 
           AND total_goal_actions < (SELECT percentile_cont(0.75) WITHIN GROUP (ORDER BY total_goal_actions) FROM user_activity) THEN 'medium'
      ELSE 'low'
    END AS activity_segment,
    -- Количество использований каждой функции
    choose_utm_source_count,
    short_utm_result_count,
    add_parameter_click_count,
    delete_parameter_click_count,
    final_modal_open_count,
    modal_edit_count,
    modal_copy_count
  FROM
    user_activity
),


activity_segment AS (
SELECT
  activity_segment,
  COUNT(DISTINCT client_id) AS users_count,
  -- Средние показатели по сегментам
  ROUND(AVG(total_goal_actions), 1) AS avg_goal_actions,
  ROUND(AVG(total_events), 1) AS avg_events,
  -- Процент пользователей, использовавших каждую функцию
  ROUND(100.0 * SUM(CASE WHEN choose_utm_source_count > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_used_choose_source,
  ROUND(100.0 * SUM(CASE WHEN short_utm_result_count > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_used_shortener,
  ROUND(100.0 * SUM(CASE WHEN add_parameter_click_count > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_used_add_param,
  ROUND(100.0 * SUM(CASE WHEN delete_parameter_click_count > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_used_delete_param,
  ROUND(100.0 * SUM(CASE WHEN final_modal_open_count > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_used_final_modal,
  ROUND(100.0 * SUM(CASE WHEN modal_edit_count > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_used_edit,
  ROUND(100.0 * SUM(CASE WHEN modal_copy_count > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_used_copy,
  -- Среднее количество использований функций на пользователя
  ROUND(AVG(choose_utm_source_count), 1) AS avg_choose_source,
  ROUND(AVG(short_utm_result_count), 1) AS avg_shortener,
  ROUND(AVG(add_parameter_click_count), 1) AS avg_add_param,
  ROUND(AVG(delete_parameter_click_count), 1) AS avg_delete_param,
  ROUND(AVG(final_modal_open_count), 1) AS avg_final_modal,
  ROUND(AVG(modal_edit_count), 1) AS avg_edit,
  ROUND(AVG(modal_copy_count), 1) AS avg_copy
FROM
  user_segments
GROUP BY
  activity_segment
ORDER BY
CASE activity_segment WHEN 'high' THEN 1 WHEN 'medium' THEN 2 ELSE 3 END
  )
SELECT * FROM activity_segment
