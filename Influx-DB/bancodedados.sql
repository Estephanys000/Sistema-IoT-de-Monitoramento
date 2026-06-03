SELECT *
FROM "dados_grafana"
WHERE
time >= now() - interval '1 hour'
AND
("aceleracao" IS NOT NULL OR "panico" IS NOT NULL)
AND
"id_idoso" IN ('idoso_01','idoso_02')